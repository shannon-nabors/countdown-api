require 'sinatra'
require "sinatra/namespace"
require 'pry'
require 'rack/contrib'
require_relative 'CountdownSolver'

use Rack::JSONBodyParser

namespace '/api/v1' do
    before do
        content_type 'application/json'
    end

    post '/solve' do
        solver = CountdownSolver.new(goal: params[:target], numbers: params[:numbers], big: params[:big], little: params[:little])
        return {"errors": solver.errors}.to_json if !solver.errors.empty?

        target, numbers = solver.goal, solver.numbers
        solutions = solver.run
        solutions = "No exact solutions were found." if solutions.empty?

        {"target": target, "numbers": numbers, "solutions": solutions}.to_json
    end

end