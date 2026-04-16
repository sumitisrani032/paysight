module Api
  module V1
    class EmployeesController < ApplicationController
      def create
        employee = Employee.new(employee_params)

        if employee.save
          render json: { employee: employee }, status: :created
        else
          render json: { errors: employee.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def employee_params
        params.require(:employee).permit(
          :full_name, :email, :job_title, :country,
          :salary, :currency, :employment_status, :date_of_joining
        )
      end
    end
  end
end
