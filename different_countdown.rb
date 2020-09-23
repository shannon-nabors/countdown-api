require 'pry'
require 'benchmark'
require 'colorize'

class CountdownSolver

    @@big = [25, 50, 75, 100]
    @@little = [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10]
    @@operators = ["+", "-", "/", "*"]
    @@ops = {
        "+": Proc.new { |a, b| (a && b) ? a + b : false },
        # both numbers must be present
        "-": Proc.new { |a, b| (a && b && a != b && a-b != b && a>b) ? a - b : false },
        # both numbers must be present
        # can't be the same number (no point in subtracting them)
        # the difference can't be equal to one of the numbers (again, no point)
        "*": Proc.new { |a, b| (a && b && a > 1 && b > 1) ? a * b : false },
        # both numbers must be present
        # neither number can be 1 (no point in multiplying)
        "/": Proc.new { |a, b| (a && b && a % b == 0 && b != 1 && a/b != b) ? a / b : false }
        # both numbers must be present
        # the answer must be a whole number, as per the rules of Countdown
        # divisor can't be 1 (no point)
        # quotient can't be equal to one of the numbers (again, no point)
    }

    attr_reader :goal, :numbers
    attr_accessor :pairs, :solutions

    def initialize() #(big, little)
        @goal = 499#self.get_goal
        @numbers = [100, 75, 8, 8, 4, 1]#self.get_numbers
        @pairs, @solutions = {}, []
    end

    def get_numbers(big, little)
        @@big.sample(big) + @@little.sample(little)
    end

    def get_goal
        (101...1000).to_a.sample
    end

    def duplicates?(pair)
        return true if self.numbers.count(pair[0]) > 1
        return true if self.numbers.count(pair[1]) > 1
        return false
    end
    
    def remove_pair_from_pool(pair)
        if duplicates?(pair)
            pool = self.numbers.clone() 
            pair.each {|num| pool.delete_at(pool.index(num))} 
        else
            pool = self.numbers - pair
        end
    
        return pool
    end

    def run
        puts "\nGOAL: ", self.goal
        puts "\nNUMBERS: ", self.numbers
    
        self.separate
        self.add_three_sets
        self.solve
    end

    def separate
        self.numbers.each_with_index do |number, index|
            next_index = index + 1
            while next_index < self.numbers.length
                results = {}
                next_number = self.numbers[next_index]
    
                results["#{number}+#{next_number}"] = @@ops[:+].call(number, next_number)
                results["#{number}-#{next_number}"] = @@ops[:-].call(number, next_number)
                results["#{number}*#{next_number}"] = @@ops[:*].call(number, next_number)
                results["#{number}/#{next_number}"] = @@ops[:/].call(number, next_number)
    
                self.pairs[[number, next_number]] = results
    
                next_index += 1
            end
        end
    end

    def add_three_sets
        three_sets = []
        
        self.pairs.each do |pair, possibilities|
            pool = remove_pair_from_pool(pair)
    
            pool.each do |num|
                if num <= pair[1]
                    three_set = pair.clone() << num
                    three_sets << three_set
                end
            end
        end
        
        three_sets = three_sets.uniq
        # Find a better way to do this
        
        three_sets.each do |set|
            a, b, c, set_possibilities = set[0], set[1], set[2], {}
            self.pairs[set] = set_possibilities
            set_possibilities["#{a}+#{b}+#{c}"] = @@ops[:+].call(@@ops[:+].call(a, b), c)
            set_possibilities["#{a}+#{b}-#{c}"] = @@ops[:-].call(@@ops[:+].call(a, b), c)
            set_possibilities["#{a}-#{b}+#{c}"] = @@ops[:+].call(@@ops[:-].call(a, b), c)
            set_possibilities["#{a}-#{b}-#{c}"] = @@ops[:-].call(@@ops[:-].call(a, b), c)
            set_possibilities["#{b}+#{c}-#{a}"] = @@ops[:-].call(@@ops[:+].call(b, c), a)
            set_possibilities["(#{a}+#{b})*#{c}"] = @@ops[:*].call(@@ops[:+].call(a, b), c)
            set_possibilities["#{a}+(#{b}*#{c})"] = @@ops[:+].call(a, @@ops[:*].call(c, b))
            set_possibilities["(#{a}+#{b})/#{c}"] = @@ops[:/].call(@@ops[:+].call(a, b), c)
            set_possibilities["#{a}+(#{b}/#{c})"] = @@ops[:+].call(a, @@ops[:/].call(b, c))
            set_possibilities["(#{a}-#{b})/#{c}"] = @@ops[:/].call(@@ops[:-].call(a, b), c)
            set_possibilities["#{a}-(#{b}/#{c})"] = @@ops[:-].call(a, @@ops[:/].call(b, c))
            set_possibilities["(#{a}-#{b})*#{c}"] = @@ops[:*].call(@@ops[:-].call(a, b), c)
            set_possibilities["#{a}-(#{b}*#{c})"] = @@ops[:-].call(a, @@ops[:*].call(b, c))
            set_possibilities["(#{a}*#{b})+#{c}"] = @@ops[:+].call(@@ops[:*].call(a, b), c)
            set_possibilities["#{a}*(#{b}+#{c})"] = @@ops[:*].call(a, @@ops[:+].call(b, c))
            set_possibilities["(#{a}*#{b})-#{c}"] = @@ops[:-].call(@@ops[:*].call(a, b), c)
            set_possibilities["#{a}*(#{b}-#{c})"] = @@ops[:*].call(a, @@ops[:-].call(b, c))
            set_possibilities["(#{a}/#{b})+#{c}"] = @@ops[:+].call(@@ops[:/].call(a, b), c)
            set_possibilities["#{a}/(#{b}+#{c})"] = @@ops[:/].call(a, @@ops[:+].call(b, c))
            set_possibilities["(#{a}/#{b})-#{c}"] = @@ops[:-].call(@@ops[:/].call(a, b), c)
            set_possibilities["#{a}/(#{b}-#{c})"] = @@ops[:/].call(a, @@ops[:-].call(b, c))
            set_possibilities["(#{a}+#{c})/#{b}"] = @@ops[:/].call(@@ops[:+].call(a, c), b)
            set_possibilities["(#{a}-#{c})/#{b}"] = @@ops[:/].call(@@ops[:-].call(a, c), b)
            set_possibilities["(#{a}+#{c})*#{b}"] = @@ops[:*].call(@@ops[:+].call(a, c), b)
            set_possibilities["(#{a}-#{c})*#{b}"] = @@ops[:*].call(@@ops[:-].call(a, c), b)
            set_possibilities["(#{a}*#{c})+#{b}"] = @@ops[:+].call(@@ops[:*].call(a, c), b)
            set_possibilities["(#{a}/#{c})+#{b}"] = @@ops[:+].call(@@ops[:/].call(a, c), b)
            set_possibilities["(#{a}*#{c})-#{b}"] = @@ops[:-].call(@@ops[:*].call(a, c), b)
            set_possibilities["(#{a}/#{c})-#{b}"] = @@ops[:-].call(@@ops[:/].call(a, c), b)
            set_possibilities["(#{b}+#{c})/#{a}"] = @@ops[:/].call(@@ops[:+].call(b, c), a)
            set_possibilities["(#{b}*#{c})-#{a}"] = @@ops[:-].call(@@ops[:*].call(b, c), a)
            set_possibilities["#{b}-(#{a}/#{c})"] = @@ops[:-].call(b, @@ops[:/].call(a, c))
            set_possibilities["#{b}/(#{a}-#{c})"] = @@ops[:/].call(b, @@ops[:-].call(a, c))
            set_possibilities["#{c}-(#{a}/#{b})"] = @@ops[:-].call(c, @@ops[:/].call(a, b))
            set_possibilities["#{c}/(#{a}-#{b})"] = @@ops[:/].call(c, @@ops[:-].call(a, b))
            set_possibilities["#{a}*#{b}*#{c}"] = @@ops[:*].call(@@ops[:*].call(a, b), c)
            set_possibilities["#{a}/#{b}/#{c}"] = @@ops[:/].call(@@ops[:/].call(a, b), c)
            set_possibilities["#{a}/#{b}*#{c}"] = @@ops[:*].call(@@ops[:/].call(a, b), c)
            set_possibilities["#{a}*#{b}/#{c}"] = @@ops[:/].call(@@ops[:*].call(a, b), c)
            set_possibilities["#{b}/#{c}*#{a}"] = @@ops[:*].call(@@ops[:/].call(b, c), a)
        end
    end

    def possible_operands(set)
        operands = (set.length < 6 ? set.clone() : [])
        if set.length == 3
            operands << set
        end
        set.each_with_index do |n, i|
            index = i + 1
            while index < set.length
                a, b = n, set[index]
                if !operands.include?([a, b])
                    operands << [a, b]
                end
                index += 1
            end
        end
        return operands
    end

    def hanging_plus_or_minus(solution_string)
        # returns true if solution needs to be wrapped in ()
        return false if !solution_string.match?(/[+-]/)
        return true if !solution_string.match?(/[)]/)
    
        string = solution_string.clone()
    
        open_index = string.index("(")
        close_index = string.chars.count - string.reverse.index(")")
        parenthetical = string.slice(open_index, close_index - open_index)
        string = string.sub(parenthetical, "")
        
        return true if string.match?(/[+-]/)
        return false
    end

    def try_all_ops(number_one, number_two, solution, pool, addendum)
        @@ops.each do |sym, operation|
            sol_copy = solution.clone()
    
            a = (number_one > number_two ? number_one : number_two)
            b = (number_one > number_two ? number_two : number_one)
    
            new_number = operation.call(a, b)
            next if !new_number
    
            if sym == :* && addendum && (addendum.include?("+") || addendum.include?("-"))
                addendum = "(" + addendum + ")"
            end
    
            if sym == :/ && addendum
                addendum = "(" + addendum + ")"
            end
    
            if a == number_two && a != b && sym == :- && addendum && !addendum.include?("+") && !addendum.include?("-")
                if solution.include?("+") || solution.include?("-")
                    solution = "(" + solution + ")"
                end
                solution = addendum + sym.to_s + solution
            elsif a == number_two && a != b && (sym == :- || sym == :/)
                solution = "(" + solution + ")"
                if addendum
                    solution = addendum + sym.to_s + solution
                else
                    solution = number_two.to_s + sym.to_s + solution
                end
            elsif (sym == :* || sym == :/) && hanging_plus_or_minus(solution)
                solution = "(" + solution + ")"
                if addendum
                    solution = solution + sym.to_s + addendum
                else
                    solution = solution + sym.to_s + number_two.to_s
                end
            else
                if addendum && sym == :-
                    solution = solution + sym.to_s + "(" + addendum + ")"
                elsif addendum
                    solution = solution + sym.to_s + addendum
                else
                    solution = solution + sym.to_s + number_two.to_s
                end
            end
    
            if new_number == self.goal
                self.solutions << solution
            end
    
            if !pool.empty?
                exhaust_pool(pool, new_number, solution)
            end
    
            solution = sol_copy
        end
    end

    def exhaust_pool(pool, num, solution)

        set_of_combos = possible_operands(pool)
    
        set_of_combos.each do |combo|
            if combo.class == Integer
    
                if pool.count(combo) > 1
                    pool.delete_at(pool.index(combo))
                else
                    pool = pool - [combo]
                end
    
                addendum = "^^" + combo.to_s + "^^"
                # addendum = combo.to_s
    
                try_all_ops(num, combo, solution, pool, addendum)
                pool << combo
                pool = pool.sort.reverse
    
            elsif combo.class == Array
                combo = combo.sort.reverse
                # please fix
    
                if pool == combo
                    pool = []
                elsif self.numbers.count(combo[0]) > 1
                    pool.delete_at(pool.index(combo[0]))
                    pool = pool - [combo[1]]
                elsif self.numbers.count(combo[1]) > 1
                    pool.delete_at(pool.index(combo[1]))
                    pool = pool - [combo[0]]
                else
                    pool = pool - combo
                end
    
                self.pairs[combo].each do |op_string, number|
                    if number
                        addendum = "|||" + op_string + "|||"
                        # addendum = op_string
                        try_all_ops(num, number, solution, pool, addendum)
                    end
                end
    
                pool << combo
                pool = pool.flatten.sort.reverse
    
            end
        end
    end

    def solve
        # binding.pry
        self.pairs.each do |pair, possibilities|
            possibilities.each do |op_string, num|
                if num
                    pool = remove_pair_from_pool(pair)
                    # pool = $numbers.clone() 
                    # pair.each {|num| pool.delete_at(pool.index(num))} 
    
                    solution = "..." + op_string + "..."
                    # solution = op_string
                    if num == self.goal
                        self.solutions << solution
                        next
                    end
                    exhaust_pool(pool, num, solution)
                end
            end
        end
    
        puts ""
        puts "SOLUTIONS:"
    
        duplicate_checker = {}
    
        self.solutions.each_with_index do |solution, index|
            sol_string = index.to_s + "  ------>  " + solution
            if duplicate_checker[solution]
                puts sol_string.red
            else
                puts sol_string
            end
            duplicate_checker[solution] = "x"
        end
    
        puts ""
        puts "TIME:"
    
    end

end

solver = CountdownSolver.new

puts Benchmark.realtime { solver.run }
puts ""
puts "ERRORS:"

# $solutions.each do |solution|
#     if eval(solution) != $goal
#         puts solution + "  ------->  " + eval(solution).to_s
#     end
# end