require "rails_helper"

describe("Truck OpenDates API") do
  before(:each) do
    @food_truck = create(:food_truck)
    @open_dates = create_list(:open_date, 5, food_truck: @food_truck)

    @food_truck_2 = create(:food_truck)
    @other_open_date = create(:open_date, food_truck: @food_truck_2)
  end

  describe("GET /food_trucks/:id/open_dates") do
    it("returns list of open_dates for specified truck") do

      get "/api/v1/food_trucks/#{@food_truck.id}/open_dates"

      all_open_dates = JSON.parse(response.body, symbolize_names: true)

      expect(response).to be_successful
      expect(all_open_dates).to have_key(:data)
      expect(all_open_dates[:data]).to have_key(:id)
      expect(all_open_dates[:data][:id]).to eq(@food_truck.id.to_s)
      expect(all_open_dates).to have_key(:included)
      expect(all_open_dates[:included].count).to eq(5)
      expect(all_open_dates[:included][0]).to have_key(:id)
      expect(all_open_dates[:included][0]).to have_key(:attributes)
      expect(all_open_dates[:included][0][:attributes]).to have_key(:id)
      expect(all_open_dates[:included][0][:attributes]).to have_key(:date)
      expect(all_open_dates[:included][0][:attributes]).to have_key(:booked?)
    end

    it('returns 400 if truck does not exist') do
      get "/api/v1/food_trucks/500/open_dates"

      data = JSON.parse(response.body, symbolize_names: true)

      expect(response.status).to eq(400)
      expect(data).to have_key(:message)
      expect(data[:message]).to eq("Sorry, that food truck does not exist, please try again.")
    end
  end

  describe("GET /api/v1/food_trucks/:food_truck_id/open_dates/:id") do
    it("should return only the specified open date") do
      target_open_date = @open_dates.second

      get "/api/v1/food_trucks/#{@food_truck.id}/open_dates/#{target_open_date.id}"

      target_data = JSON.parse(response.body, symbolize_names: true)

      expect(response).to be_successful
      expect(target_data).to have_key(:data)
      expect(target_data[:data]).to have_key(:id)
      expect(target_data[:data][:id]).to eq(target_open_date.id.to_s)
      expect(target_data[:data]).to have_key(:attributes)
      expect(target_data[:data][:attributes]).to have_key(:date)
      expect(target_data[:data][:attributes][:date]).to eq(target_open_date.date.strftime('%Y-%m-%d'))
      expect(target_data[:data][:attributes]).to have_key(:booked?)
      expect(target_data[:data][:attributes][:booked?]).to eq(target_open_date.booked?)
    end

    it("should return 404 when truck not found") do
      target_open_date = @open_dates.second

      get "/api/v1/food_trucks/#{FoodTruck.last.id + 500}/open_dates/#{target_open_date.id}"

      error_data = JSON.parse(response.body, symbolize_names: true)

      expect(response.status).to eq(404)
      expect(error_data[:message]).to eq("Could not locate resource.")
    end

    it("should return 404 when open date not found") do
      get "/api/v1/food_trucks/#{@food_truck.id}/open_dates/#{OpenDate.last.id + 500}"

      error_data = JSON.parse(response.body, symbolize_names: true)

      expect(response.status).to eq(404)
      expect(error_data[:message]).to eq("Could not locate resource.")
    end
  end

  describe("POST /api/v1/food_truck/:food_truck_id/open_dates") do
    it('should create new open_date') do
      new_open_date_attributes = attributes_for(:open_date)

      post "/api/v1/food_trucks/#{@food_truck.id}/open_dates", params: new_open_date_attributes

      expect(response).to be_successful
      expect(response.status).to eq(201)
      expect(@food_truck.open_dates.count).to eq(6)
      expect(@food_truck.open_dates.last[:date]).to eq(new_open_date_attributes[:date])
    end

    it('should return 400 if params not valid') do
      post "/api/v1/food_trucks/#{@food_truck.id}/open_dates", params: {booked?: true}

      error = JSON.parse(response.body, symbolize_names: true)

      expect(response.status).to eq(400)
      expect(error[:message]).to eq("Could not save, please try again.")
    end
  end
end
