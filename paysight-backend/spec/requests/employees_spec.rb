require "rails_helper"

RSpec.describe "Employees API", type: :request do
  let(:valid_params) do
    {
      employee: {
        full_name: "John Doe",
        email: "john@example.com",
        job_title: "Software Engineer",
        country: "India",
        salary: 75_000.00,
        currency: "USD",
        employment_status: "active",
        date_of_joining: "2023-01-15"
      }
    }
  end

  describe "POST /api/v1/employees" do
    it "creates an employee with valid data and returns 201" do
      post "/api/v1/employees", params: valid_params

      expect(response).to have_http_status(:created)

      body = JSON.parse(response.body)
      expect(body["employee"]["full_name"]).to eq("John Doe")
      expect(body["employee"]["email"]).to eq("john@example.com")
      expect(body["employee"]["id"]).to be_present
    end

    it "returns 422 with validation errors when required fields are missing" do
      post "/api/v1/employees", params: { employee: { currency: "USD" } }

      expect(response).to have_http_status(:unprocessable_entity)

      body = JSON.parse(response.body)
      expect(body["errors"]).to include(/full name/i)
      expect(body["errors"]).to include(/salary/i)
    end

    it "returns 422 when email is already taken" do
      create(:employee, email: "john@example.com")

      post "/api/v1/employees", params: valid_params

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]).to include(/email/i)
    end

    it "returns 422 when email format is invalid" do
      invalid = valid_params.deep_merge(employee: { email: "not-an-email" })

      post "/api/v1/employees", params: invalid

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 400 when params are empty" do
      post "/api/v1/employees", params: {}

      expect(response).to have_http_status(:bad_request)
      expect(response.content_type).to include("application/json")
    end
  end
end
