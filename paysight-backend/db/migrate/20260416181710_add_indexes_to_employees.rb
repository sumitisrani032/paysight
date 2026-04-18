class AddIndexesToEmployees < ActiveRecord::Migration[8.0]
  def change
    add_index :employees, [:email, :country, :job_title, :employment_status],
              name: "idx_employees_email_country_title_status"
  end
end
