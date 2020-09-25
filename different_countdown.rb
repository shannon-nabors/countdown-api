require 'pry'
require 'benchmark'
require 'colorize'

class CountdownSolver

    @@big = [25, 50, 75, 100]
    @@little = [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10]
    @@operators = ["+", "-", "/", "*"]

    # Each operation proc returns either the combination of two numbers using that operation,
    # or, to cut down on solve time,
    # FALSE if the result would be against the rules in Countdown (negative number, non-whole number)
    # or if it wouldn't be useful to do that operation (i.e. it gives us a number we already have)
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

    ###############################

    def get_numbers(big, little)
        @@big.sample(big) + @@little.sample(little)
    end


    def get_goal
        (101...1000).to_a.sample
    end


    def run
        puts "\nGOAL: ", self.goal
        puts "\nNUMBERS: ", self.numbers
    
        self.separate_into_pairs
        self.add_three_sets_to_pairs
        self.solve
    end

    ############################### CREATING PAIRS

    # Creates a hash where each possible pair of numbers points to
    # all the numbers that could be made from combining them.
    #
    # Example:
    # [100, 75, 8, 8, 4, 1] --> {[100, 75] => {"100+75"=>175, "100-75"=>25, "100*75"=>7500, "100/75"=>false},
    #                            [100, 8]=>{"100+8"=>108, "100-8"=>92, "100*8"=>800, "100/8"=>false},
    #                             etc. }

    def separate_into_pairs
        self.numbers.each_with_index do |num, index|
            pair_number_with_each_remaining(num, index)
            # ex) If num is 75, it will be paired with 8, 4, and 1
        end
    end


    def pair_number_with_each_remaining(num, index)
        # num --> 100, index --> 0
        next_index = index + 1 # 1
        return if next_index >= self.numbers.length

        next_num = self.numbers[next_index] # 75

        if pairs_not_yet_generated(num, next_num)
            self.pairs[[num, next_num]] = all_possible_numbers_from_combining(num, next_num)
        end
        # pairs --> {[100, 75] => {"100+75"=>175, "100-75"=>25, "100*75"=>7500, "100/75"=>false}}

        pair_number_with_each_remaining(num, next_index) # next number will be 8, last will be 1
    end


    def all_possible_numbers_from_combining(a, b)
        results = {}

        results["#{a}+#{b}"] = @@ops[:+].call(a, b)
        results["#{a}-#{b}"] = @@ops[:-].call(a, b)
        results["#{a}*#{b}"] = @@ops[:*].call(a, b)
        results["#{a}/#{b}"] = @@ops[:/].call(a, b)

        return results

        # ex) a --> 100, b --> 8
        # results --> {"100+8"=>108, "100-8"=>92, "100*8"=>800, "100/8"=>false}
    end


    def pairs_not_yet_generated(a, b)
        !self.pairs[[a, b]]
    end

    ############################### CREATING THREE-SETS
    
    # Adds to the pairs hash all possible combinations of three numbers from the set.
    # Each set points to all the unique numbers that could be made from combining them.
    #
    # Example:
    # self.pairs now includes...
    # [100, 75, 8]=> {"100+75+8"=>183, "100+75-8"=>167, "100-75+8"=>33, "100-75-8"=>17,"75+8-100"=>false...}
    # etc.
    #
    # This is necessary because some solutions involve combining two numbers
    # that themselves can only be gotten by combining three numbers.
    #
    # Example:
    # (75*8)+1-(100+(8/4))
    # (75*8)+1 = 601        100+(8/4) = 102         601-102 = 499
    #
    # This solution is valid, but can't be achieved by only combining pairs and single numbers.


    def generate_three_sets
        three_sets = []
        
        self.pairs.each do |pair, possibilities| # pair --> [100, 75]
            pool = pool_with_pair_removed(pair) # pool --> [8, 8, 4, 1]
    
            pool.each do |num|
                if num <= pair[1] # is there a better way to handle this?
                    three_set = pair.clone() << num
                    three_sets << three_set
                end
            end
        end

        return three_sets.uniq
        # Find a better way to do this
    end

    def add_three_sets_to_pairs
        
        three_sets = self.generate_three_sets
        
        three_sets.each do |set|
            a, b, c, set_possibilities = set[0], set[1], set[2], {}
            self.pairs[set] = set_possibilities
            CountdownSolver.three_set_hash(a, b, c).each do |op_string, number|
                set_possibilities[op_string] = number
            end
        end
    end

    ################################## SOLVING

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
    
                # addendum = "^^" + combo.to_s + "^^"
                addendum = combo.to_s
    
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
                        # addendum = "|||" + op_string + "|||"
                        addendum = op_string
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
                    pool = pool_with_pair_removed(pair)
                    # pool = $numbers.clone() 
                    # pair.each {|num| pool.delete_at(pool.index(num))} 
    
                    # solution = "..." + op_string + "..."
                    solution = op_string
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

    ############## Helper methods ################

    def pool_with_pair_removed(pair)
        if one_number_appears_twice_in_number_set?(pair)
            remove_numbers_without_removing_duplicates(pair)
        else
            just_remove_the_numbers(pair)
        end
    end

    def one_number_appears_twice_in_number_set?(pair)
        return true if self.numbers.count(pair[0]) > 1
        return true if self.numbers.count(pair[1]) > 1
        return false
    end

    def remove_numbers_without_removing_duplicates(pair)
        pool = self.numbers.clone() 
        pair.each {|num| pool.delete_at(pool.index(num))}
        return pool
    end

    def just_remove_the_numbers(pair)
        return self.numbers - pair
    end

    ##################### Class methods ###################

    def self.three_set_hash(a, b, c)
        {"#{a}+#{b}+#{c}" => @@ops[:+].call(@@ops[:+].call(a, b), c), "#{a}+#{b}-#{c}" => @@ops[:-].call(@@ops[:+].call(a, b), c),
         "#{a}-#{b}+#{c}" => @@ops[:+].call(@@ops[:-].call(a, b), c), "#{a}-#{b}-#{c}" => @@ops[:-].call(@@ops[:-].call(a, b), c),
         "#{b}+#{c}-#{a}" => @@ops[:-].call(@@ops[:+].call(b, c), a), "(#{a}+#{b})*#{c}" => @@ops[:*].call(@@ops[:+].call(a, b), c),
         "#{a}+(#{b}*#{c})" => @@ops[:+].call(a, @@ops[:*].call(c, b)), "(#{a}+#{b})/#{c}" => @@ops[:/].call(@@ops[:+].call(a, b), c),
         "#{a}+(#{b}/#{c})" => @@ops[:+].call(a, @@ops[:/].call(b, c)), "(#{a}-#{b})/#{c}" => @@ops[:/].call(@@ops[:-].call(a, b), c),
         "#{a}-(#{b}/#{c})" => @@ops[:-].call(a, @@ops[:/].call(b, c)), "(#{a}-#{b})*#{c}" => @@ops[:*].call(@@ops[:-].call(a, b), c),
         "#{a}-(#{b}*#{c})" => @@ops[:-].call(a, @@ops[:*].call(b, c)), "(#{a}*#{b})+#{c}" => @@ops[:+].call(@@ops[:*].call(a, b), c),
         "#{a}*(#{b}+#{c})" => @@ops[:*].call(a, @@ops[:+].call(b, c)), "(#{a}*#{b})-#{c}" => @@ops[:-].call(@@ops[:*].call(a, b), c),
         "#{a}*(#{b}-#{c})" => @@ops[:*].call(a, @@ops[:-].call(b, c)), "(#{a}/#{b})+#{c}" => @@ops[:+].call(@@ops[:/].call(a, b), c),
         "#{a}/(#{b}+#{c})" => @@ops[:/].call(a, @@ops[:+].call(b, c)), "(#{a}/#{b})-#{c}" => @@ops[:-].call(@@ops[:/].call(a, b), c),
         "#{a}/(#{b}-#{c})" => @@ops[:/].call(a, @@ops[:-].call(b, c)), "(#{a}+#{c})/#{b}" => @@ops[:/].call(@@ops[:+].call(a, c), b),
         "(#{a}-#{c})/#{b}" => @@ops[:/].call(@@ops[:-].call(a, c), b), "(#{a}+#{c})*#{b}" => @@ops[:*].call(@@ops[:+].call(a, c), b),
         "(#{a}-#{c})*#{b}" => @@ops[:*].call(@@ops[:-].call(a, c), b), "(#{a}*#{c})+#{b}" => @@ops[:+].call(@@ops[:*].call(a, c), b),
         "(#{a}/#{c})+#{b}" => @@ops[:+].call(@@ops[:/].call(a, c), b), "(#{a}*#{c})-#{b}" => @@ops[:-].call(@@ops[:*].call(a, c), b),
         "(#{a}/#{c})-#{b}" => @@ops[:-].call(@@ops[:/].call(a, c), b), "(#{b}+#{c})/#{a}" => @@ops[:/].call(@@ops[:+].call(b, c), a),
         "(#{b}*#{c})-#{a}" => @@ops[:-].call(@@ops[:*].call(b, c), a), "#{b}-(#{a}/#{c})" => @@ops[:-].call(b, @@ops[:/].call(a, c)),
         "(#{b}*#{c})-#{a}" => @@ops[:-].call(@@ops[:*].call(b, c), a), "#{b}-(#{a}/#{c})" => @@ops[:-].call(b, @@ops[:/].call(a, c)),
         "#{b}/(#{a}-#{c})" => @@ops[:/].call(b, @@ops[:-].call(a, c)), "#{c}-(#{a}/#{b})" => @@ops[:-].call(c, @@ops[:/].call(a, b)),
         "#{c}/(#{a}-#{b})" => @@ops[:/].call(c, @@ops[:-].call(a, b)), "#{a}*#{b}*#{c}" => @@ops[:*].call(@@ops[:*].call(a, b), c),
         "#{a}/#{b}/#{c}" => @@ops[:/].call(@@ops[:/].call(a, b), c), "#{a}/#{b}*#{c}" => @@ops[:*].call(@@ops[:/].call(a, b), c),
         "#{a}*#{b}/#{c}" => @@ops[:/].call(@@ops[:*].call(a, b), c), "#{b}/#{c}*#{a}" => @@ops[:*].call(@@ops[:/].call(b, c), a)}
    end

end

solver = CountdownSolver.new

puts Benchmark.realtime { solver.run }
puts ""
puts "ERRORS:"

solver.solutions.each do |solution|
    if eval(solution) != solver.goal
        puts solution + "  ------->  " + eval(solution).to_s
    end
end