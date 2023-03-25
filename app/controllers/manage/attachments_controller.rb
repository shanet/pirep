class Manage::AttachmentsController < ApplicationController
  before_action :set_attachment, only: :destroy

  def index
    @attachments = policy_scope(ActiveStorage::Attachment.where(record_type: 'Airport').where(name: 'contributed_photos').order(created_at: :desc).page(params[:page]),
                                policy_scope_class: Manage::AttachmentPolicy::Scope)
    authorize @attachments, policy_class: Manage::AttachmentPolicy
  end

  def show
  end

  def destroy
    if @attachment.destroy
      redirect_to manage_attachments_path, notice: 'Photo deleted successfully'
    else
      redirect_to manage_attachments_path
    end
  end

private

  def set_attachment
    @attachment = ActiveStorage::Attachment.find(params[:id])
    authorize @attachment, policy_class: Manage::AttachmentPolicy
  end
end
