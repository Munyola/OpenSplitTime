require "rails_helper"

# t.integer  "course_id"
# t.integer  "race_id"
# t.string   "name"
# t.datetime "first_start_time"
# t.datetime "created_at", null: false
# t.datetime "updated_at", null: false

RSpec.describe Event, type: :model do
  it "should be valid when created with a course, a name, and a start date" do
    course = Course.create!(name: 'Slo Mo 100 CCW')
    event = Event.create!(course_id: course.id, name: 'Slo Mo 100 2015', first_start_time: "2015-07-01 06:00:00")

    expect(Event.all.count).to eq(1)
    expect(event.course_id).to eq(course.id)
    expect(event.name).to eq('Slo Mo 100 2015')
    expect(event.first_start_time).to eq("2015-07-01 06:00:00".to_datetime)
    expect(event).to be_valid
  end

  it "should be invalid without a course_id" do
    event = Event.new(course_id: nil, name: 'Slo Mo 100 2015', first_start_time: "2015-07-01")
    expect(event).not_to be_valid
    expect(event.errors[:course_id]).to include("can't be blank")
  end

  it "should be invalid without a name" do
    course = Course.create!(name: 'Slo Mo 100 CCW')
    event = Event.new(course_id: course.id, name: nil, first_start_time: "2015-07-01")
    expect(event).not_to be_valid
    expect(event.errors[:name]).to include("can't be blank")
  end

  it "should be invalid without a start date" do
    course = Course.create!(name: 'Slo Mo 100 CCW')
    event = Event.new(course_id: course.id, name: 'Slo Mo 100 2015', first_start_time: nil)
    expect(event).not_to be_valid
    expect(event.errors[:first_start_time]).to include("can't be blank")
  end

  it "should not allow for duplicate names" do
    course1 = Course.create!(name: 'Slo Mo 100 CW')
    course2 = Course.create!(name: 'Slo Mo 100 CCW')
    Event.create!(course_id: course1.id, name: 'Slo Mo 100 2015', first_start_time: "2015-07-01")
    event = Event.new(course_id: course2.id, name: 'Slo Mo 100 2015', first_start_time: "2016-07-01")
    expect(event).not_to be_valid
    expect(event.errors[:name]).to include("has already been taken")
  end

end