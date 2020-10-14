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

    attr_reader :target, :big, :little
    attr_accessor :numbers, :pairs, :solutions, :errors

    def initialize(args)
        @errors = []
        @target = (args[:target] ? args[:target].to_i : nil)
        @big = (args[:big] ? args[:big].to_i : nil)
        @little = (args[:little] ? args[:little].to_i : nil)
        @numbers = (args[:numbers]? parse_numbers(args[:numbers]) : nil)
        self.check_for_errors

        @target ||= self.get_target
        @numbers ||= self.get_numbers(@big, @little)

        # @target = target #499
        # @numbers = numbers #[100, 75, 8, 8, 4, 1] 
        @pairs, @solutions = {}, []
    end

    ###############################

    def get_numbers(big, little)
        (@@big.sample(big) + @@little.sample(little)).sort.reverse
    end


    def get_target
        (101...1000).to_a.sample
    end

    def parse_numbers(nums)
        nums.split(",").map(&:to_i)
    end


    def check_for_errors
        if !self.arguments_match?
            self.errors << "The parameters you've submitted are not allowed."
            return
        end

        self.check_big_and_little
        self.check_target
        self.check_numbers
    end


    def arguments_match?
        return false if (self.big && !self.little) || (self.little && !self.big)
        return false if (self.target && !self.numbers) || (self.numbers && !self.target)
        return true
    end


    def check_big_and_little
        self.errors << "There are only four big numbers available." if self.big && self.big > 4
        self.errors << "You must have six total numbers." if self.big && self.big + self.little != 6
    end


    def check_target
        if self.target
            self.errors << "The target number must be between 101 and 999." if (self.target < 101 || self.target > 999)
        end
    end
    
    def check_numbers
        if self.numbers
            self.numbers = self.numbers.sort.reverse

            if self.numbers.length != 6
                self.errors << "You must have six total numbers."
                return
            end

            nums = Hash.new(0)
            self.numbers.each do |number|
                if number > 100 || number < 1 || (number > 10 && number%25 != 0)
                    self.errors << "Your numbers must be either from 1-10 or 25, 50, 75 or 100."
                    return
                end

                if number > 10 && nums[number] > 0
                    self.errors << "25, 50, 75 and 100 can each only be used once."
                    return
                end

                if nums[number] > 1
                    self.errors << "Small numbers can only be used twice"
                    return
                end

                nums[number] += 1
            end
        end
    end


    def run
        # puts "\ntarget: ", self.target
        # puts "\nNUMBERS: ", self.numbers
        
        self.separate_into_pairs(self.numbers)
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

    def separate_into_pairs(number_array, operand_array=nil)
        number_array.each_with_index do |num, index|
            pair_number_with_each_remaining(number_array, num, index, operand_array)
            # ex) If num is 75, it will be paired with 8, 4, and 1
        end
    end


    def pair_number_with_each_remaining(number_array, num, index, operand_array=nil)
        # num --> 100, index --> 0
        next_index = index + 1 # 1
        return if next_index >= number_array.length

        next_num = number_array[next_index] # 75

        if operand_array
            operand_array << [num, next_num] if !operand_array.include?([num, next_num])
        else
            if pairs_not_yet_generated(num, next_num)
                self.pairs[[num, next_num]] = all_possible_numbers_from_combining(num, next_num)
            end
            # pairs --> {[100, 75] => {"100+75"=>175, "100-75"=>25, "100*75"=>7500, "100/75"=>false}}
        end
            

        pair_number_with_each_remaining(number_array, num, next_index, operand_array) # next number will be 8, last will be 1
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
        # This generates an array of all the possible sets of three numbers for self.numbers
        # e.g. [[100, 75, 8], [100, 75, 8], [100, 75, 4]...]
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
        # I would ideally like to find a better way to do this
    end


    def add_three_sets_to_pairs
        # Adds every three_set as a key in self.pairs, pointing to all possible unique combos of those 3 numbers

        three_sets = self.generate_three_sets # [[100, 75, 8], [100, 75, 8], [100, 75, 4]...]
        
        three_sets.each do |set| # set --> [100, 75, 8]
            a, b, c, set_possibilities = set[0], set[1], set[2], {}
            self.pairs[set] = set_possibilities
            # self.pairs now includes [100, 75, 8] => {}

            CountdownSolver.three_set_hash(a, b, c).each do |op_string, number|
                set_possibilities[op_string] = number
            end
            # self.pairs now includes [100, 75, 8] => {"100+75+8"=>183, "100+75-8"=>167...}
        end
    end

    ################################## SOLVING

    def possible_operands(number_set)
        # returns all the numbers/sets of numbers that can be made from the remaining pool
        # ex. number_set --> [8, 8, 4, 1], operands --> [8, 8, 4, 1, [8, 8], [8, 4], [8, 1], [4, 1]]

        operands = number_set.clone() # all the individual numbers should be potential operands

        operands << number_set if number_set.length == 3
        # if there are only 3 numbers left in the pool, we need to try treating them as a set,
        # in case there's a solution that requires a combination of those three numbers

        separate_into_pairs(number_set, operands)
        return operands
    end


    def hanging_plus_or_minus(solution_string)
        # returns true if solution needs to be wrapped in ()
        string = solution_string.clone().gsub(/\(([^)]+?)\)/, "") 
        return string.match?(/[+-]/)
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
    
            if new_number == self.target
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
                # addendum = combo.to_s
    
                try_all_ops(num, combo, solution, pool, false)
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
                    if num == self.target
                        self.solutions << solution
                        next
                    end
                    exhaust_pool(pool, num, solution)
                end
            end
        end
    
        # puts "\nSOLUTIONS:"
    
        # duplicate_checker = {}
        # duplicates = 0
    
        # self.solutions.each_with_index do |solution, index|
        #     sol_string = index.to_s + "  ------>  " + solution
        #     if duplicate_checker[solution]
        #         puts sol_string.red
        #         duplicates += 1
        #     else
        #         puts sol_string
        #     end
        #     duplicate_checker[solution] = "x"
        # end

        # puts "\nDUPLICATES: #{duplicates}"
    
        # puts "\nTIME:"
    
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
        # These are the unique numbers you can get from combining 3 numbers
        # i.e. If you know a/b/c = x, you don't need to try a/c/b -- it'll be x
        # These are hard-coded since they won't change, to cut down on computation time
        
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

# solver = CountdownSolver.new

# puts Benchmark.realtime { solver.run }
# puts ""
# puts "ERRORS:"

# solver.solutions.each do |solution|
#     if eval(solution) != solver.target
#         puts solution + "  ------->  " + eval(solution).to_s
#     end
# end