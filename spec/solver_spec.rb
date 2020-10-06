require 'colorize'
require_relative '../CountdownSolver.rb'

describe "Countdown Solver" do
    describe 'Individual methods' do
        describe 'hanging_plus_or_minus' do
            it 'returns true if given string needs to be wrapped in parentheses' do
                solver = CountdownSolver.new({big: 3, little: 3})
                yes = solver.hanging_plus_or_minus("75*50/(2)-(25*5)")
                no = solver.hanging_plus_or_minus("75*50/(2-(25*5))")
                expect(yes).to eq true
                expect(no).to eq false
            end
        end
    end

    describe 'General' do
        it "returns only correct solutions" do
            solver = CountdownSolver.new(big: 3, little: 3)
            puts "TARGET: #{solver.target} *** NUMBERS: #{solver.numbers}"
            solver.run
            errors = 0
            solver.solutions.each_with_index do |solution, index|
                if solver.target == eval(solution)
                    puts "#{index+1} ---- #{solution} ---> #{eval(solution)}".light_cyan
                else
                    puts "#{index+1} ---- #{solution} ---> #{eval(solution)}".red
                    errors += 1
                end
            end
            expect(errors).to eq 0
        end

        it "isn't redundant" do 
            solver = CountdownSolver.new(big: 3, little: 3)
            puts "TARGET: #{solver.target} *** NUMBERS: #{solver.numbers}"
            solver.run
            duplicate_checker = {}
            duplicates =
            0
            solver.solutions.each_with_index do |solution, index|
                sol_string = index.to_s + "  ------>  " + solution
                if duplicate_checker[solution]
                    puts sol_string.red
                    duplicates += 1
                else
                    puts sol_string.light_cyan
                end
                duplicate_checker[solution] = "x"
            end

            puts "\nDUPLICATES: #{duplicates}"
            expect(duplicates).to eq 0
        end
    end
end