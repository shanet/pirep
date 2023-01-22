class MaxmindDbUpdaterJob < ApplicationJob
  def perform
    MaxmindDb.client.update_database!
  end
end
