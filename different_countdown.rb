require 'pry'
require 'benchmark'

$goal = 0
$numbers = []

BIG = [25, 50, 75, 100]
LITTLE = [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10]
OPERATORS = ["+", "-", "/", "*"]


def get_numbers(big, little)
    return if big + little != 6
    BIG.sample(big) + LITTLE.sample(little)
end


def get_goal
    (101...1000).to_a.sample
end

def run
    $goal = get_goal#109
    $numbers = get_numbers(2, 4).sort.reverse#[100, 75, 50, 25, 8, 3]
    puts ""
    puts "GOAL: ", $goal
    puts ""
    puts "NUMBERS: ", $numbers

    separate($numbers)
    add_three_sets
    solve
end

$pairs = {}
$solutions = []

OPS = {
    "+": Proc.new { |a, b| a && b ? a + b : false },
    "-": Proc.new { |a, b| (a && b && a != b && a-b != b && a>b) ? a - b : false },
    "*": Proc.new { |a, b| a && b && a > 1 && b > 1 ? a * b : false },
    "/": Proc.new { |a, b| (a && b && a % b == 0 && b != 1 && a/b != b && a>=b) ? a / b : false }
}


def separate(nums)
    nums.each_with_index do |n, i|
        index = i + 1
        while index < nums.length
            a, b, results = n, nums[index], {}

            results["#{a}+#{b}"] = OPS[:+].call(a, b)
            results["#{a}-#{b}"] = OPS[:-].call(a, b)
            results["#{a}*#{b}"] = OPS[:*].call(a, b)
            results["#{a}/#{b}"] = OPS[:/].call(a, b)

            $pairs[[a, b]] = results

            index += 1
        end
    end
end

def add_three_sets
    three_sets = []
    
    $pairs.each do |pair, possibilities|
        if $numbers.count(pair[0]) > 1
            pool = $numbers.clone()
            pair.each {|num| pool.delete_at(pool.index(num))}
        elsif $numbers.count(pair[1]) > 1
            pool = $numbers.clone()
            pair.each {|num| pool.delete_at(pool.index(num))}
        else
            pool = $numbers - pair
        end

        pool.each do |num|
            if num <= pair[1]
                three_set = pair.clone() << num
                three_sets << three_set
            end
        end
    end
    
    three_sets = three_sets.uniq
    # Please for the love of god come back and find a better way to do this
    
    three_sets.each do |set|
        a, b, c, set_possibilities = set[0], set[1], set[2], {}
        $pairs[set] = set_possibilities
        set_possibilities["#{a}+#{b}+#{c}"] = OPS[:+].call(OPS[:+].call(a, b), c)
        set_possibilities["#{a}+#{b}-#{c}"] = OPS[:-].call(OPS[:+].call(a, b), c)
        set_possibilities["#{a}-#{b}+#{c}"] = OPS[:+].call(OPS[:-].call(a, b), c)
        set_possibilities["#{a}-#{b}-#{c}"] = OPS[:-].call(OPS[:-].call(a, b), c)
        set_possibilities["#{b}+#{c}-#{a}"] = OPS[:-].call(OPS[:+].call(b, c), a)
        set_possibilities["(#{a}+#{b})*#{c}"] = OPS[:*].call(OPS[:+].call(a, b), c)
        set_possibilities["#{a}+(#{b}*#{c})"] = OPS[:+].call(a, OPS[:*].call(c, b))
        set_possibilities["(#{a}+#{b})/#{c}"] = OPS[:/].call(OPS[:+].call(a, b), c)
        set_possibilities["#{a}+(#{b}/#{c})"] = OPS[:+].call(a, OPS[:/].call(b, c))
        set_possibilities["(#{a}-#{b})/#{c}"] = OPS[:/].call(OPS[:-].call(a, b), c)
        set_possibilities["#{a}-(#{b}/#{c})"] = OPS[:-].call(a, OPS[:/].call(b, c))
        set_possibilities["(#{a}-#{b})*#{c}"] = OPS[:*].call(OPS[:-].call(a, b), c)
        set_possibilities["#{a}-(#{b}*#{c})"] = OPS[:-].call(a, OPS[:*].call(b, c))
        set_possibilities["(#{a}*#{b})+#{c}"] = OPS[:+].call(OPS[:*].call(a, b), c)
        set_possibilities["#{a}*(#{b}+#{c})"] = OPS[:*].call(a, OPS[:+].call(b, c))
        set_possibilities["(#{a}*#{b})-#{c}"] = OPS[:-].call(OPS[:*].call(a, b), c)
        set_possibilities["#{a}*(#{b}-#{c})"] = OPS[:*].call(a, OPS[:-].call(b, c))
        set_possibilities["(#{a}/#{b})+#{c}"] = OPS[:+].call(OPS[:/].call(a, b), c)
        set_possibilities["#{a}/(#{b}+#{c})"] = OPS[:/].call(a, OPS[:+].call(b, c))
        set_possibilities["(#{a}/#{b})-#{c}"] = OPS[:-].call(OPS[:/].call(a, b), c)
        set_possibilities["#{a}/(#{b}-#{c})"] = OPS[:/].call(a, OPS[:-].call(b, c))
        set_possibilities["(#{a}+#{c})/#{b}"] = OPS[:/].call(OPS[:+].call(a, c), b)
        set_possibilities["(#{a}-#{c})/#{b}"] = OPS[:/].call(OPS[:-].call(a, c), b)
        set_possibilities["(#{a}+#{c})*#{b}"] = OPS[:*].call(OPS[:+].call(a, c), b)
        set_possibilities["(#{a}-#{c})*#{b}"] = OPS[:*].call(OPS[:-].call(a, c), b)
        set_possibilities["(#{a}*#{c})+#{b}"] = OPS[:+].call(OPS[:*].call(a, c), b)
        set_possibilities["(#{a}/#{c})+#{b}"] = OPS[:+].call(OPS[:/].call(a, c), b)
        set_possibilities["(#{a}*#{c})-#{b}"] = OPS[:-].call(OPS[:*].call(a, c), b)
        set_possibilities["(#{a}/#{c})-#{b}"] = OPS[:-].call(OPS[:/].call(a, c), b)
        set_possibilities["(#{b}+#{c})/#{a}"] = OPS[:/].call(OPS[:+].call(b, c), a)
        set_possibilities["(#{b}*#{c})-#{a}"] = OPS[:-].call(OPS[:*].call(b, c), a)
        set_possibilities["#{b}-(#{a}/#{c})"] = OPS[:-].call(b, OPS[:/].call(a, c))
        set_possibilities["#{b}/(#{a}-#{c})"] = OPS[:/].call(b, OPS[:-].call(a, c))
        set_possibilities["#{c}-(#{a}/#{b})"] = OPS[:-].call(c, OPS[:/].call(a, b))
        set_possibilities["#{c}/(#{a}-#{b})"] = OPS[:/].call(c, OPS[:-].call(a, b))
        set_possibilities["#{a}*#{b}*#{c}"] = OPS[:*].call(OPS[:*].call(a, b), c)
        set_possibilities["#{a}/#{b}/#{c}"] = OPS[:/].call(OPS[:/].call(a, b), c)
        set_possibilities["#{a}/#{b}*#{c}"] = OPS[:*].call(OPS[:/].call(a, b), c)
        set_possibilities["#{a}*#{b}/#{c}"] = OPS[:/].call(OPS[:*].call(a, b), c)
        set_possibilities["#{b}/#{c}*#{a}"] = OPS[:*].call(OPS[:/].call(b, c), a)
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
    OPS.each do |sym, operation|
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
        # figure out a way to make sure ) is after + or -
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

        if new_number == $goal
            $solutions << solution
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

            try_all_ops(num, combo, solution, pool, false)
            pool << combo
            pool = pool.sort.reverse

        elsif combo.class == Array
            combo = combo.sort.reverse
            # please fix

            if pool == combo
                pool = []
            elsif $numbers.count(combo[0]) > 1
                pool.delete_at(pool.index(combo[0]))
                pool = pool - [combo[1]]
            elsif $numbers.count(combo[1]) > 1
                pool.delete_at(pool.index(combo[1]))
                pool = pool - [combo[0]]
            else
                pool = pool - combo
            end

            $pairs[combo].each do |op_string, number|
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
    $pairs.each do |pair, possibilities|

        possibilities.each do |op_string, num|
            if num
                if pair.count(pair[1]) > 1
                    pool = $numbers.clone()
                    pair.each {|num| pool.delete_at(pool.index(num))}
                elsif $numbers.count(pair[0]) > 1
                    pool = $numbers.clone()
                    pair.each {|num| pool.delete_at(pool.index(num))}
                elsif $numbers.count(pair[1]) > 1
                    pool = $numbers.clone()
                    pair.each {|num| pool.delete_at(pool.index(num))}
                else
                    pool = $numbers - pair
                end

                # solution = "..." + op_string + "..."
                solution = op_string
                if num == $goal
                    $solutions << solution
                    next
                end
                exhaust_pool(pool, num, solution)
            end
        end
    end

    puts ""
    puts "SOLUTIONS:"

    $solutions.uniq.each_with_index do |solution, index|
        puts index.to_s + "  ------>  " + solution
    end

    puts ""
    puts "TIME:"

end

puts Benchmark.realtime { run }
puts ""
puts "ERRORS:"

$solutions.each do |solution|
    if eval(solution) != $goal
        puts solution + "  ------->  " + eval(solution).to_s
    end
end