# frozen_string_literal: true

class EffortQuery < BaseQuery

  def self.rank_and_status(args = {})
    select_sql = sql_select_from_string(args[:fields], permitted_column_names, '*')
    order_sql = sql_order_from_hash(args[:sort], permitted_column_names, 'overall_rank')
    query = <<-SQL
      WITH
        existing_scope AS (#{existing_scope_sql}),

        efforts_scoped AS 
          (SELECT efforts.*
           FROM efforts
           INNER JOIN existing_scope ON existing_scope.id = efforts.id),

        stopped_split_time_subquery AS 
          (SELECT  split_times.id as stopped_split_time_id, 
                   split_times.lap as stopped_lap, 
                   split_times.split_id as stopped_split_id, 
                   split_times.sub_split_bitkey as stopped_bitkey, 
                   split_times.time_from_start as stopped_time, 
                   split_times.effort_id
           FROM split_times
           WHERE effort_id in (select id from efforts_scoped) and stopped_here = true),

        course_subquery AS 
          (SELECT courses.id as course_id, splits.distance_from_start as course_distance
           FROM courses
           INNER JOIN splits ON splits.course_id = courses.id
           WHERE splits.kind = 1),

        base_subquery AS 
          (SELECT DISTINCT ON(efforts_scoped.id) 
                              efforts_scoped.*,
                              events.laps_required,
                              events.start_time as event_start_time,
                              events.home_time_zone as event_home_zone,
                              splits.base_name as final_split_name,
                              splits.distance_from_start as final_lap_distance,
                              split_times.lap as final_lap,
                              split_times.split_id as final_split_id, 
                              split_times.sub_split_bitkey as final_bitkey,
                              split_times.time_from_start as final_time,
                              split_times.id as final_split_time_id,
                              stopped_split_time_id,
                              stopped_lap,
                              stopped_split_id,
                              stopped_bitkey,
                              stopped_time,
                              course_distance,
                              CASE
                                when splits.kind = 1 then true else false 
                              end 
                              AS final_lap_complete,
                              CASE 
                                when split_times.lap > 1 OR splits.kind IN (1, 2) then true else false
                              end
                              AS beyond_start
           FROM efforts_scoped
              LEFT JOIN split_times ON split_times.effort_id = efforts_scoped.id 
              LEFT JOIN splits ON splits.id = split_times.split_id
              LEFT JOIN events ON events.id = efforts_scoped.event_id
              LEFT JOIN course_subquery ON events.course_id = course_subquery.course_id
              LEFT JOIN stopped_split_time_subquery ON split_times.effort_id = stopped_split_time_subquery.effort_id
           ORDER BY  efforts_scoped.id, 
                    final_lap desc,
                    final_lap_distance desc, 
                    final_bitkey desc,
                    stopped_time desc),

        distance_subquery AS 
          (SELECT *, 
              CASE when final_lap is null then false else true end AS started,
              final_lap AS laps_started,
              CASE when final_lap_complete is true then final_lap else final_lap - 1 end AS laps_finished,
              (final_lap - 1) * course_distance + final_lap_distance AS final_distance
           FROM base_subquery),

        finished_subquery AS 
          (SELECT *,
              CASE 
              when laps_required = 0 then
                CASE when stopped_split_time_id is null then false else true END  
              else
                CASE when laps_finished >= laps_required then true else false END 
              END
              AS finished,
              CASE
                when not started and checked_in and (event_start_time + start_offset * interval '1 second') AT TIME ZONE 'UTC' < current_timestamp then true else false
              END
              AS ready_to_start
           FROM distance_subquery),

        stopped_subquery AS 
          (SELECT *,
              CASE when finished or stopped_split_time_id is not null then true else false end AS stopped
           FROM finished_subquery),

        main_subquery AS 
          (SELECT *,
              CASE when stopped and not finished then true else false END AS dropped
           FROM stopped_subquery)

      SELECT #{select_sql},
          rank() over 
            (ORDER BY started desc,
                      dropped, 
                      final_lap desc NULLS LAST, 
                      final_lap_distance desc, 
                      final_bitkey desc, 
                      final_time, 
                      gender desc, 
                      age desc) 
          AS overall_rank, 
          rank() over 
            (PARTITION BY gender 
             ORDER BY started desc,
                      dropped, 
                      final_lap desc NULLS LAST, 
                      final_lap_distance desc, 
                      final_bitkey desc, 
                      final_time, 
                      gender desc, 
                      age desc) 
          AS gender_rank
      FROM main_subquery
      ORDER BY #{order_sql}
    SQL
    query.squish
  end

    def self.over_segment(segment)
    begin_id = segment.begin_id
    begin_bitkey = segment.begin_bitkey
    end_id = segment.end_id
    end_bitkey = segment.end_bitkey

    query = <<-SQL
      WITH
        existing_scope AS (#{existing_scope_sql}),
        
        efforts_scoped AS (SELECT efforts.*
                           FROM efforts
                           INNER JOIN existing_scope ON existing_scope.id = efforts.id),
                                       
        stopped_split_time_subquery AS (SELECT split_times.id as stopped_split_time_id, 
                                           split_times.lap as stopped_lap, 
                                           split_times.split_id as stopped_split_id, 
                                           split_times.sub_split_bitkey as stopped_bitkey, 
                                           split_times.time_from_start as stopped_time, 
                                           split_times.effort_id
                                      FROM split_times
                                      WHERE stopped_here = true),
                                      
        farthest_split_time_subquery AS (SELECT DISTINCT ON(split_times.effort_id)
                            split_times.effort_id, 
                                    splits.distance_from_start as final_lap_distance,
                                    split_times.lap as final_lap,
                                    split_times.sub_split_bitkey as final_bitkey,
                                    CASE
                                      when splits.kind = 1 then true else false 
                                    end 
                                    AS final_lap_complete
                                FROM split_times
                                    LEFT JOIN splits ON splits.id = split_times.split_id
                                ORDER BY  split_times.effort_id, 
                                          final_lap desc,
                                          final_lap_distance desc, 
                                          final_bitkey desc),
                                          
        final_split_time_subquery AS (SELECT *,                       
                            CASE
                          when final_lap_complete is true then final_lap 
                          else final_lap - 1 
                          end 
                          AS laps_finished
                        FROM farthest_split_time_subquery),
      
      
        main_subquery AS   (SELECT e1.*, (tfs_end - tfs_begin) as segment_seconds
                  FROM 
                      (SELECT efforts_scoped.*, 
                              events.start_time as event_start_time, 
                              events.home_time_zone as event_home_zone, 
                              split_times.effort_id, 
                              split_times.time_from_start as tfs_begin, 
                              split_times.lap, 
                              split_times.split_id, 
                              split_times.sub_split_bitkey,
                              events.laps_required,
                              event_groups.concealed as event_group_concealed
                      FROM efforts_scoped
                        INNER JOIN split_times ON split_times.effort_id = efforts_scoped.id 
                        INNER JOIN events ON events.id = efforts_scoped.event_id
                        INNER JOIN event_groups ON event_groups.id = events.event_group_id
                      WHERE split_times.split_id = #{begin_id} AND split_times.sub_split_bitkey = #{begin_bitkey}) 
                  as e1, 
                      (SELECT efforts_scoped.id, 
                              split_times.effort_id, 
                              split_times.time_from_start as tfs_end, 
                              split_times.lap, 
                              split_times.split_id, 
                              split_times.sub_split_bitkey 
                      FROM efforts_scoped
                      INNER JOIN split_times ON split_times.effort_id = efforts_scoped.id 
                      WHERE split_times.split_id = #{end_id} AND split_times.sub_split_bitkey = #{end_bitkey}) 
                  as e2 
                  WHERE (e1.effort_id = e2.effort_id AND e1.lap = e2.lap))
                
      
      SELECT main_subquery.*, 
              lap, 
              rank() over (order by segment_seconds, gender, -age, lap) as overall_rank, 
              rank() over (partition by gender order by segment_seconds, -age) as gender_rank,
              CASE 
              when main_subquery.laps_required = 0 then
                CASE when stopped_split_time_id is null then false else true END  
              else
                CASE when laps_finished >= laps_required then true else false END 
              END
              as finished
      FROM main_subquery 
        LEFT JOIN stopped_split_time_subquery ON stopped_split_time_subquery.effort_id = main_subquery.effort_id
        LEFT JOIN final_split_time_subquery ON final_split_time_subquery.effort_id = main_subquery.effort_id
      WHERE event_group_concealed = 'f'
      ORDER BY overall_rank
    SQL
    query.squish
  end

  def self.existing_scope_sql
    # have to do this to get the binds interpolated. remove any ordering and just grab the ID
    Effort.connection.unprepared_statement { Effort.reorder(nil).select('id').to_sql }
  end

  def self.permitted_column_names
    EffortParameters.enriched_query
  end
end
