# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2023_12_29_073752) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "cube"
  enable_extension "earthdistance"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "actions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "type"
    t.uuid "user_id", null: false
    t.string "actionable_type"
    t.uuid "actionable_id"
    t.uuid "version_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actionable_type", "actionable_id"], name: "index_actions_on_actionable"
    t.index ["user_id"], name: "index_actions_on_user_id"
    t.index ["version_id"], name: "index_actions_on_version_id"
  end

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "airports", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.float "latitude", null: false
    t.float "longitude", null: false
    t.string "facility_type"
    t.string "facility_use"
    t.string "ownership_type"
    t.text "description"
    t.text "transient_parking"
    t.text "fuel_location"
    t.text "crew_car"
    t.text "landing_fees"
    t.text "wifi"
    t.integer "elevation", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "landing_rights"
    t.string "landing_requirements"
    t.string "diagram"
    t.datetime "reviewed_at", precision: nil
    t.point "coordinates"
    t.datetime "faa_data_cycle", precision: nil
    t.float "bbox_ne_latitude"
    t.float "bbox_ne_longitude"
    t.float "bbox_sw_latitude"
    t.float "bbox_sw_longitude"
    t.boolean "bbox_checked", default: false, null: false
    t.jsonb "annotations"
    t.string "city"
    t.string "state"
    t.float "city_distance"
    t.string "sectional"
    t.datetime "activation_date", precision: nil
    t.string "fuel_types", array: true
    t.datetime "locked_at", precision: nil
    t.string "cover_image", default: "default", null: false
    t.datetime "external_photos_updated_at", precision: nil
    t.uuid "featured_photo_id"
    t.string "icao_code"
    t.datetime "external_photos_enqueued_at", precision: nil
    t.text "flying_clubs"
    t.string "timezone"
    t.datetime "timezone_checked_at", precision: nil
    t.string "country"
    t.string "data_source"
    t.index ["code"], name: "index_airports_on_code", unique: true
    t.index ["featured_photo_id"], name: "index_airports_on_featured_photo_id"
  end

  create_table "comments", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "airport_id", null: false
    t.text "body"
    t.integer "helpful_count", default: 0
    t.datetime "outdated_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.datetime "reviewed_at", precision: nil
    t.index ["airport_id"], name: "index_comments_on_airport_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "location"
    t.string "host"
    t.string "url"
    t.datetime "start_date", precision: nil
    t.datetime "end_date", precision: nil
    t.string "recurring_cadence"
    t.integer "recurring_interval"
    t.integer "recurring_day_of_month"
    t.integer "recurring_week_of_month"
    t.uuid "airport_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "data_source"
    t.string "digest"
    t.index ["airport_id"], name: "index_events_on_airport_id"
    t.index ["digest", "airport_id"], name: "index_events_on_digest_and_airport_id", unique: true
  end

  create_table "faa_data_cycles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "airports"
    t.string "charts"
    t.string "diagrams"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.jsonb "serialized_properties"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_discard"
    t.text "callback_queue_name"
    t.integer "callback_priority"
    t.datetime "enqueued_at"
    t.datetime "discarded_at"
    t.datetime "finished_at"
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id", null: false
    t.text "job_class"
    t.text "queue_name"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.text "error"
    t.integer "error_event", limit: 2
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "key"
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "performed_at"
    t.datetime "finished_at"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at"
    t.uuid "batch_id"
    t.uuid "batch_callback_id"
    t.boolean "is_discrete"
    t.integer "executions_count"
    t.text "job_class"
    t.integer "error_event", limit: 2
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["active_job_id"], name: "index_good_jobs_on_active_job_id"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at", unique: true
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "pageviews", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "user_id", null: false
    t.string "user_agent"
    t.string "browser"
    t.string "browser_version"
    t.string "operating_system"
    t.float "latitude"
    t.float "longitude"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id"], name: "index_pageviews_on_record"
    t.index ["user_id"], name: "index_pageviews_on_user_id"
  end

  create_table "postgres_cache_store", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.text "value"
    t.jsonb "entry"
    t.index ["key"], name: "index_postgres_cache_store_on_key", unique: true
  end

  create_table "read_onlies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "enabled", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "remarks", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "element", null: false
    t.text "text", null: false
    t.uuid "airport_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["airport_id"], name: "index_remarks_on_airport_id"
  end

  create_table "runways", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "number", null: false
    t.integer "length", null: false
    t.string "surface"
    t.string "lights"
    t.uuid "airport_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["airport_id"], name: "index_runways_on_airport_id"
  end

  create_table "searches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "searchable_type", null: false
    t.uuid "searchable_id", null: false
    t.tsvector "term_vector", null: false
    t.string "term", null: false
    t.point "coordinates"
    t.index ["searchable_id", "searchable_type", "term"], name: "searches_next_searchable_id_searchable_type_term_idx1", unique: true
    t.index ["searchable_type", "searchable_id"], name: "searches_next_searchable_type_searchable_id_idx1"
    t.index ["term_vector"], name: "searches_next_term_vector_idx1", using: :gin
  end

  create_table "tags", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.uuid "airport_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["airport_id"], name: "index_tags_on_airport_id"
    t.index ["name", "airport_id"], name: "index_tags_on_name_and_airport_id", unique: true
  end

  create_table "users", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "type", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ip_address"
    t.datetime "last_edit_at", precision: nil
    t.datetime "last_seen_at", precision: nil
    t.datetime "reviewed_at", precision: nil
    t.datetime "disabled_at", precision: nil
    t.string "timezone"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["ip_address"], name: "index_users_on_ip_address", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "versions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "item_type", null: false
    t.string "item_id", null: false
    t.string "event", null: false
    t.string "airport_id"
    t.string "whodunnit"
    t.jsonb "object"
    t.jsonb "object_changes"
    t.datetime "created_at"
    t.datetime "reviewed_at", precision: nil
    t.datetime "reverted_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "weather_reports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.float "dewpoint"
    t.float "temperature"
    t.integer "visibility"
    t.integer "wind_direction"
    t.integer "wind_gusts"
    t.integer "wind_speed"
    t.jsonb "cloud_layers"
    t.uuid "airport_id", null: false
    t.string "flight_category"
    t.string "raw"
    t.string "type"
    t.string "weather"
    t.datetime "ends_at", precision: nil
    t.datetime "observed_at", precision: nil
    t.datetime "starts_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["airport_id"], name: "index_weather_reports_on_airport_id"
  end

  create_table "webcams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "airport_id", null: false
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["airport_id"], name: "index_webcams_on_airport_id"
    t.index ["url", "airport_id"], name: "index_webcams_on_url_and_airport_id", unique: true
  end

  add_foreign_key "actions", "users"
  add_foreign_key "actions", "versions"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "airports", "active_storage_attachments", column: "featured_photo_id", on_delete: :nullify
  add_foreign_key "comments", "airports"
  add_foreign_key "comments", "users"
  add_foreign_key "events", "airports"
  add_foreign_key "pageviews", "users"
  add_foreign_key "remarks", "airports"
  add_foreign_key "runways", "airports"
  add_foreign_key "tags", "airports"
  add_foreign_key "weather_reports", "airports"
  add_foreign_key "webcams", "airports"
end
