class CreateGoodJobs < ActiveRecord::Migration[7.0]
  def change
    enable_extension 'pgcrypto'

    create_table :good_jobs, id: :uuid do |table|
      table.text :queue_name
      table.integer :priority
      table.jsonb :serialized_params
      table.datetime :scheduled_at
      table.datetime :performed_at
      table.datetime :finished_at
      table.text :error

      table.timestamps

      table.uuid :active_job_id
      table.text :concurrency_key
      table.text :cron_key
      table.uuid :retried_good_job_id
      table.datetime :cron_at
    end

    create_table :good_job_processes, id: :uuid do |table|
      table.timestamps
      table.jsonb :state
    end

    create_table :good_job_settings, id: :uuid do |table|
      table.timestamps
      table.text :key
      table.jsonb :value
      table.index :key, unique: true
    end

    add_index :good_jobs, :scheduled_at, where: '(finished_at IS NULL)', name: 'index_good_jobs_on_scheduled_at'
    add_index :good_jobs, [:queue_name, :scheduled_at], where: '(finished_at IS NULL)', name: :index_good_jobs_on_queue_name_and_scheduled_at
    add_index :good_jobs, [:active_job_id, :created_at], name: :index_good_jobs_on_active_job_id_and_created_at
    add_index :good_jobs, :concurrency_key, where: '(finished_at IS NULL)', name: :index_good_jobs_on_concurrency_key_when_unfinished
    add_index :good_jobs, [:cron_key, :created_at], name: :index_good_jobs_on_cron_key_and_created_at
    add_index :good_jobs, [:cron_key, :cron_at], name: :index_good_jobs_on_cron_key_and_cron_at, unique: true
    add_index :good_jobs, [:active_job_id], name: :index_good_jobs_on_active_job_id
    add_index :good_jobs, [:finished_at], where: 'retried_good_job_id IS NULL AND finished_at IS NOT NULL', name: :index_good_jobs_jobs_on_finished_at
    add_index :good_jobs, [:priority, :created_at], order: {priority: 'DESC NULLS LAST', created_at: :asc},
                                                    where: 'finished_at IS NULL', name: :index_good_jobs_jobs_on_priority_created_at_when_unfinished
  end
end
