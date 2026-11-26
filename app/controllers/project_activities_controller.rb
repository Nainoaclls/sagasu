# Project activity page: the project's history for its owner and the approvers it was sent to.
class ProjectActivitiesController < ApplicationController
  def show
    @project = Project.find(params[:project_id])
    authorize @project, :activity?
    @events = ProjectTimeline.new(@project).events
  end
end
