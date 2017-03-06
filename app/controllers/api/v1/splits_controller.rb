class Api::V1::SplitsController < ApiController
  before_action :set_split, except: :create

  def show
    authorize @split
    render json: @split
  end

  def create
    split = Split.new(split_params)
    authorize split

    if split.save
      render json: split
    else
      render json: {message: 'split not created', error: "#{split.errors.full_messages}"}, status: :bad_request
    end
  end

  def update
    authorize @split
    if @split.update(split_params)
      render json: @split
    else
      render json: {message: 'split not updated', error: "#{@split.errors.full_messages}"}, status: :bad_request
    end
  end

  def destroy
    authorize @split
    if @split.destroy
      render json: @split
    else
      render json: {message: 'split not destroyed', error: "#{@split.errors.full_messages}"}, status: :bad_request
    end
  end

  private

  def set_split
    @split = Split.friendly.find(params[:id])
  end

  def split_params
    params.require(:split).permit(*Split::PERMITTED_PARAMS)
  end
end
