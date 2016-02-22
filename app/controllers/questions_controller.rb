class QuestionsController < ApplicationController
  before_filter :authenticate_user!, except: :show
  load_and_authorize_resource

  def new
    if params[:issue_id].present?
      @issue = Issue.find params[:issue_id]
      @question.issue = @issue
    end
  end

  def create
    set_issue
    @question.user = current_user
    if @question.save
      redirect_to @question
    else
      render 'new'
    end
  end

  def update
    set_issue
    if @question.update_attributes(question_params)
      redirect_to @question
    else
      render 'edit'
    end
  end

  def destroy
    @question.destroy
    redirect_to issue_home_path(@question.issue)
  end

  private

  def question_params
    params.require(:question).permit(:title, :body, :tag_list)
  end

  def set_issue
    @issue ||= Issue.find_by title: params[:issue_title]
    @question.issue = @issue
  end
end
