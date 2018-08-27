# frozen_string_literal: true

module EventsHelper

  def link_to_edit_event(view_object)
    link_to 'Edit event', edit_event_path(view_object.event), class: 'btn btn-sm btn-primary'
  end

  def link_to_delete_event(view_object)
    link_to 'Delete event', event_path(view_object.event, referrer_path: events_path),
            method: :delete,
            data: {confirm: 'NOTE: This will delete the event and all associated efforts and split times. ' +
                'This action cannot be undone. Are you sure you want to go ahead?'},
            class: 'btn btn-sm btn-danger'
  end

  def link_to_beacon_button(view_object)
    if view_object.beacon_url
      link_to event_beacon_button_text(view_object.beacon_url),
              url_with_protocol(view_object.beacon_url),
              class: 'btn btn-sm btn-default',
              target: '_blank'
    end
  end

  def link_to_podium(view_object)
    if view_object.podium_template
      link_to 'Podium', podium_event_path(view_object.event),
              disabled: controller.action_name == 'podium',
              class: 'btn btn-sm btn-primary'
    end
  end

  def link_to_traffic(view_object)
      link_to 'Traffic', traffic_event_group_path(view_object.event_group),
              disabled: controller.action_name == 'traffic',
              class: 'btn btn-sm btn-primary'
  end

  def link_to_raw_times(view_object, current_user)
    if current_user&.authorized_to_edit?(view_object.event_group)
      link_to 'Raw times', raw_times_event_group_path(view_object.event_group),
              disabled: controller.action_name == 'raw_times',
              class: 'btn btn-sm btn-primary'
      content_tag :li, class: "#{'active' if action_name == 'podium'}" do
        link_to 'Podium', podium_event_path(view_object.event)
      end
    end
  end

  def link_to_event_staging(view_object, current_user)
    if current_user&.authorized_to_edit?(view_object.event)
      content_tag :li, class: "#{'active' if action_name == 'app'}" do
        link_to 'Staging', "#{event_staging_app_path(view_object.event)}#/#{event_staging_app_page(view_object)}"
      end
    end
  end

  def link_to_roster(view_object, current_user)
    if current_user&.authorized_to_edit?(view_object.event_group)
      content_tag :li, class: "#{'active' if action_name == 'roster'}" do
        link_to 'Roster', "#{roster_event_group_path(view_object.event_group)}"
      end
    end
  end

  def link_to_event_group(view_object, current_user)
    if current_user&.authorized_to_edit?(view_object.event_group) || view_object.multiple_events?
      content_tag :li, class: "#{'active' if controller_name == 'event_groups' && action_name == 'show'}" do
        link_to 'Group', event_group_path(view_object.event_group, force_settings: true)
      end
    end
  end

  def link_to_download_spread_csv(view_object, current_user)
    if current_user&.authorized_to_edit?(view_object.event) && view_object.event_finished?
      link_to 'Export spreadsheet',
              spread_event_path(view_object.event, format: :csv, display_style: view_object.display_style, sort: view_object.sort_hash),
              method: :get, class: 'btn btn-md btn-success'
    end
  end

  def link_to_toggle_live_entry(view_object)
    if view_object.available_live?
      button_text = 'Disable live'
      confirm_text = "NOTE: This will suspend all live entry actions for #{view_object.event_group_names}, " +
          'including any that may be in process, and will disable live follower notifications ' +
          'by email and SMS text when new times are added. Are you sure you want to proceed?'
    else
      button_text = 'Enable live'
      confirm_text = "NOTE: This will enable live entry actions for #{view_object.event_group_names}, " +
          'and will also trigger live follower notifications by email and SMS text when new times are added. ' +
          'Are you sure you want to proceed?'
    end

    link_to button_text,
            event_group_path(view_object.event_group, event_group: {available_live: !view_object.available_live?}),
            data: {confirm: confirm_text},
            method: :put,
            class: 'btn btn-md btn-warning'
  end

  def link_to_toggle_public_private(view_object)
    if view_object.concealed?
      button_text = 'Make public'
      confirm_text = "NOTE: This will make #{view_object.event_group_names} visible to the public, " +
          'including all related efforts and people. Are you sure you want to proceed?'
    else
      button_text = 'Make private'
      confirm_text = "NOTE: This will conceal #{view_object.event_group_names} from the public, " +
          'including all related efforts. Are you sure you want to proceed?'
    end

    link_to button_text,
            event_group_path(view_object.event_group, event_group: {concealed: !view_object.concealed?}),
            data: {confirm: confirm_text},
            method: :put,
            class: 'btn btn-md btn-warning'
  end

  def link_to_toggle_ost_remote(view_object)
    if view_object.auto_live_times?
      button_text = 'OST Remote Manual'
      confirm_text = "NOTE: Times imported from OST Remote into #{view_object.event_group_names} " +
          'will need to be manually updated in the Live Entry view. Are you sure you want to proceed?'
    else
      button_text = 'OST Remote Auto'
      confirm_text = "NOTE: Times imported from OST Remote into #{view_object.event_group_names} " +
          'will be automatically updated, with only duplicate and bad times requiring attention ' +
          'in the Live Entry view. Are you sure you want to proceed?'
    end

    link_to button_text,
            event_group_path(view_object.event_group, event_group: {auto_live_times: !view_object.auto_live_times?}),
            data: {confirm: confirm_text},
            method: :put,
            class: 'btn btn-md btn-warning'
  end

  def link_to_start_ready_efforts(view_object)
    if view_object.ready_efforts.present?
      link_to "Start #{pluralize(view_object.ready_efforts_count, 'effort')}",
              start_ready_efforts_event_path(view_object.event),
              method: :put,
              data: {confirm: 'NOTE: This will create a starting split time for the ' +
                  "#{pluralize(view_object.ready_efforts_count, 'unstarted effort')} " +
                  'scheduled to start before the current time. Are you sure you want to proceed?'},
              class: 'start-ready-efforts btn btn-sm btn-success'
    else
      link_to 'Nothing to start', '#', disabled: true,
              data: {confirm: 'No efforts are ready to start. Reload the page to check again.'},
              class: 'start-ready-efforts btn btn-sm btn-success'
    end
  end

  def link_to_spread_gender(view_object, gender)
    link_to gender.titlecase, request.params.merge(filter: {gender: gender}),
            disabled: view_object.gender_text == gender
  end

  def link_to_spread_display_style(view_object, display_style, title)
    link_to title, request.params.merge(display_style: display_style),
            disabled: view_object.display_style == display_style
  end

  def link_to_display_style(view_object, display_style, title)
    link_to title, request.params.merge(display_style: display_style),
            disabled: view_object.display_style == display_style,
            class: 'btn btn-md btn-primary'
  end

  def suggested_match_id_hash(efforts)
    efforts.select(&:suggested_match).map { |effort| [effort.id, effort.suggested_match.id] }.to_h
  end

  def suggested_match_count(efforts)
    suggested_match_id_hash(efforts).size
  end

  def data_status(status_int)
    Effort.data_statuses.key(status_int)
  end

  def event_staging_app_page(view_object)
    (view_object.respond_to?(:display_style)) && (view_object.display_style == 'splits') ? 'splits' : 'entrants'
  end
end
