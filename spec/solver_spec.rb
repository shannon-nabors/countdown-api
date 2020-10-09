require 'colorize'
require_relative '../CountdownSolver.rb'

describe "Countdown Solver" do
    before(:all) do
        @solver = CountdownSolver.new(big: 3, little: 3)
        @solver.run

        puts "TARGET: #{@solver.target} *** NUMBERS: #{@solver.numbers}"
        @errors, @duplicates, @extra_parens, duplicate_checker = 0, 0, 0, {}

        @solver.solutions.each_with_index do |solution, index|
            printed_solution = "#{index+1} ---- #{solution} ---> #{eval(solution)}"
            extra_paren = solution.match?(/\(([^)*\-+\/]+?)\)/)
            if @solver.target == eval(solution) && !duplicate_checker[solution] && !extra_paren
                puts printed_solution.light_cyan
            else
                wrong, duplicate, paren = "", "", ""
                if @solver.target != eval(solution)
                    wrong = " ----- WRONG".light_yellow
                    @errors += 1
                end
                if duplicate_checker[solution]
                    duplicate = " ----- DUPL".light_blue
                    @duplicates += 1
                end
                if extra_paren
                    paren = " ----- PAREN".light_magenta
                    @extra_parens += 1
                end
                puts printed_solution.red + wrong + duplicate + paren
            end
            duplicate_checker[solution] = "x"
        end

        puts "\nERRORS: #{@errors}"
        puts "\nDUPLICATES: #{@duplicates}"
    end

    describe 'Individual methods:' do
        describe 'hanging_plus_or_minus' do
            it 'returns true if given string needs to be wrapped in parentheses' do
                @solver = CountdownSolver.new({big: 3, little: 3})
                yes = @solver.hanging_plus_or_minus("75*50/(2)-(25*5)")
                no = @solver.hanging_plus_or_minus("75*50/(2-(25*5))")
                expect(yes).to eq true
                expect(no).to eq false
            end
        end
    end

    describe 'General tests:' do
        it "returns only correct solutions" do
            expect(@errors).to eq 0
        end

        it "isn't redundant" do 
            expect(@duplicates).to eq 0
        end

        it "doesn't have parentheses wrapping single numbers" do
            expect(@extra_parens).to eq 0
        end
    end
end