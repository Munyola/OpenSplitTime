FactoryBot.define do
  factory :raw_time do
    event_group
    split_name { "#{FFaker::Name.first_name} #{FFaker::Name.first_name}".parameterize }
    bitkey { [1, 64].sample }
    bib_number { rand(1..999).to_s }
    absolute_time { FFaker::Time.datetime }
    source { 'ost-test' }

    after(:build, :stub) do |raw_time|
      raw_time.send(:parameterize_split_name)
      raw_time.send(:create_sortable_bib_number)
    end
  end
end
