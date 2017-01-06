class ImportEffortsWithoutTimesJob < ActiveJob::Base

  queue_as :default

  def perform(file_url, event, user_id)
    importer = EffortImporter.new(file_path: file_url, event: event, current_user_id: user_id)
    importer.effort_import_without_times
    importer.effort_import_report
  end

end