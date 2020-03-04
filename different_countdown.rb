require 'pry'

$goal = 0
$numbers = []

BIG = [25, 50, 75, 100]
LITTLE = (1..10).to_a
OPERATORS = ["+", "-", "/", "*"]


def get_numbers(big, little)
    return if big + little != 6
    BIG.sample(big) + LITTLE.sample(little)
end


def get_goal
    (101...1000).to_a.sample
end

def run
    $goal = 870#get_goal
    $numbers = [100, 75, 50, 25, 9, 1]#get_numbers(4, 2).sort.reverse
    puts "GOAL: ", $goal
    puts "NUMBERS: ", $numbers

    separate($numbers)
    solve
end

$pairs = {}
$solutions = []

OPS = {
    "+": Proc.new { |a, b| a + b },
    "-": Proc.new { |a, b| (a != b && a-b != b) ? a - b : false },
    "*": Proc.new { |a, b| a > 1 && b > 1 ? a * b : false },
    "/": Proc.new { |a, b| (a % b == 0 && b != 1 && a/b != b) ? a / b : false }
}


def separate(nums)
    nums.each_with_index do |n, i|
        index = i + 1
        while index < nums.length
            a, b, results = n, nums[index], {}

            results["+"] = OPS[:+].call(a, b)
            results["-"] = OPS[:-].call(a, b)
            results["*"] = OPS[:*].call(a, b)
            results["/"] = OPS[:/].call(a, b)

            $pairs[[a, b]] = results

            index += 1
        end
    end
end

def possible_operands(set)
    operands = (set.length < 6 ? set.clone() : [])
    set.each_with_index do |n, i|
        index = i + 1
        while index < set.length
            a, b = n, set[index]
            operands << [a, b]
            index += 1
        end
    end
    return operands
end

def hanging_plus_or_minus(solution_string)
    return false if (!solution_string.include?("+") && !solution_string.include?("-"))
    return true if !solution_string.include?(")")
    reversed = solution_string.reverse
    plus_index = reversed.index("+")
    minus_index = reversed.index("-")
    paren_index = reversed.index(")")
    hanging_plus = (plus_index && plus_index < paren_index)
    hanging_minus = (minus_index && minus_index < paren_index)
    return true if (hanging_plus || hanging_minus)
    return false
end

def try_all_ops(number_one, number_two, solution, pool, addendum)
    OPS.each do |sym, operation|
        sol_copy = solution.clone()

        a = (number_one > number_two ? number_one : number_two)
        b = (number_one > number_two ? number_two : number_one)

        new_number = operation.call(a, b)
        next if !new_number

        if a == number_two && a != b && (sym == :- || sym == :/)
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
            if addendum
                solution = solution + sym.to_s + addendum
            else
                solution = solution + sym.to_s + number_two.to_s
            end
        end

        if new_number == $goal
            # binding.pry
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
            pool = pool - [combo]
            try_all_ops(num, combo, solution, pool, false)
            pool << combo
            pool = pool.sort.reverse
        elsif combo.class == Array
            pool = pool - combo
            $pairs[combo].each do |operator, number|
                if number
                    addendum = "(" + combo[0].to_s + operator + combo[1].to_s + ")"
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
    $pairs.each do |pair, possibilities|
        possibilities.each do |op, num|
            if num
                pool = $numbers - pair
                solution = pair.join(op)
                # if op == "+" || op == "-"
                #     solution = "(" + solution + ")"
                # end
                if num == $goal
                    $solutions << solution
                    next
                end
                exhaust_pool(pool, num, solution)
            end
        end
    end

    $solutions.each do |solution|
        puts solution
    end
    # binding.pry
end

run
