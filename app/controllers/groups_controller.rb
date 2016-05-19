class GroupsController < ApplicationController
  before_filter :authenticate_user!, except: [:show]
  load_and_authorize_resource

  def create
    @group.user = current_user
    if @group.save
      redirect_to group_home_path(@group)
    else
      render 'new'
    end
  end

  def slug_show
    @slug = params[:slug]
    redirect_to root_path and return unless @slug.present?

    @group = Group.find_by slug: @slug
    render_404 and return unless @group.present?
  end

  def show
    redirect_to group_home_path(@group)
  end

  def update
    if @group.update_attributes(group_params)
      redirect_to group_home_path(@group)
    else
      render 'edit'
    end
  end

  def destroy
    @group.destroy
    redirect_to root_path
  end

  private

  def group_params
    params.require(:group).permit(:title, :body, :logo, :cover, :slug)
  end
end