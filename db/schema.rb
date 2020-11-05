# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_10_12_071431) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "airports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.float "latitude", null: false
    t.float "longitude", null: false
    t.string "site_number", null: false
    t.string "facility_type"
    t.string "facility_use"
    t.string "ownership_type"
    t.string "owner_name"
    t.string "owner_phone"
    t.text "description"
    t.text "transient_parking"
    t.text "fuel_location"
    t.text "crew_car"
    t.text "landing_fees"
    t.text "wifi"
    t.text "passport_location"
    t.integer "elevation", null: false
    t.string "fuel_type"
    t.string "gate_code"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["code"], name: "index_airports_on_code", unique: true
    t.index ["site_number"], name: "index_airports_on_site_number", unique: true
  end

  create_table "remarks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "element", null: false
    t.text "text", null: false
    t.uuid "airport_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["airport_id"], name: "index_remarks_on_airport_id"
  end

  create_table "runways", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "number", null: false
    t.integer "length", null: false
    t.string "surface"
    t.string "lights"
    t.uuid "airport_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["airport_id"], name: "index_runways_on_airport_id"
  end

  create_table "tags", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.uuid "airport_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["airport_id"], name: "index_tags_on_airport_id"
  end

  add_foreign_key "remarks", "airports"
  add_foreign_key "runways", "airports"
  add_foreign_key "tags", "airports"
end
