package main

import (
	"crypto/rand"
	"fmt"
	"math"
	"math/big"
	"os"
	"regexp"
	"runtime"
	"sort"
	"strconv"
	"strings"
	"sync"
)

type ExpressionResult struct {
	rolls    []int
	results  []string
	subTotal int
	total    int
	modifier int
	pretty   string
}

func random(max int) int {
	bigMax := big.NewInt(int64(max))
	startsAtZero, _ := rand.Int(rand.Reader, bigMax)
	return int(startsAtZero.Int64()) + 1
}

func roll(expression Expression) ExpressionResult {
	rolls := make([]int, expression.Casts)
	results := make([]string, expression.Casts)
	rollStrLength := len(fmt.Sprintf("%d", expression.Die))
	rollFmt := fmt.Sprintf("%%%ds", rollStrLength+2)
	subTotalFmt := fmt.Sprintf("%%%dd", rollStrLength+1)

	for i := 0; i < expression.Casts; i++ {
		var dieRoll int
		for {
			dieRoll = random(expression.Die)

			if !expression.RerollOnes || dieRoll != 1 {
				break
			}
		}

		rolls[i] = dieRoll
		results[i] = fmt.Sprintf(" %d ", dieRoll)
	}

	if expression.DropLowest {
		dupe := make([]int, expression.Casts)
		copy(dupe, rolls)
		sort.Ints(dupe)
		lowest := dupe[0]
		dropped := false

		for i := 0; i < expression.Casts; i++ {

			if !dropped && (rolls[i] == lowest) {
				dropped = true
				results[i] = fmt.Sprintf("[%d]", rolls[i])
				rolls[i] = 0
			}
		}
	}

	cast := ExpressionResult{
		rolls:    rolls,
		results:  results,
		modifier: expression.Modifier,
		total:    0,
	}

	for i := 0; i < expression.Casts; i++ {
		results[i] = fmt.Sprintf(rollFmt, results[i])
		cast.subTotal += rolls[i]
	}

	cast.total = cast.subTotal + expression.Modifier

	prettyResults := strings.Join(results, " + ")

	subTotalString := fmt.Sprintf(subTotalFmt, cast.subTotal)

	cast.pretty = fmt.Sprintf("%s : %s = %s", expression.Pretty, prettyResults, subTotalString)

	if expression.Modifier > 0 {
		cast.pretty = fmt.Sprintf("%s + %d = %d", cast.pretty, expression.Modifier, cast.total)
	}

	if expression.Modifier < 0 {
		cast.pretty = fmt.Sprintf("%s - %d = %d", cast.pretty, int(math.Abs(float64(expression.Modifier))), cast.total)
	}

	return cast
}

func Roll(expression Expression) []string {
	rolls := make([]string, expression.Iterations)

	for i := 0; i < expression.Iterations; i++ {
		expressionResult := roll(expression)
		rolls[i] = expressionResult.pretty
	}

	return rolls
}

func RollAndPrint(expression Expression) {
	rolls := Roll(expression)
	fmt.Println(strings.Join(rolls, "\n"))
}

type Expression struct {
	Iterations int
	Modifier   int
	Casts      int
	Die        int
	DropLowest bool
	RerollOnes bool
	Pretty     string
}

type RawExpression string
type ExpressionArgs []string

func parseIntFromString(str string) (int, error) {
	asInt, err := strconv.ParseInt(str, 0, 32)

	return int(asInt), err
}

func split(raw RawExpression) ExpressionArgs {
	cleaner1 := regexp.MustCompile(`\s+`)
	cleaner2 := regexp.MustCompile(`[^xXdDrR\d\+\-]`)
	spacer1 := regexp.MustCompile(`(?P<modifier>[\-\+]*)(?P<digits>\d+)`)
	spacer2 := regexp.MustCompile(`(?P<xd>[xXdD]+)(?P<digits>\d+)`)
	deduper := regexp.MustCompile(`([dD]|[xX]|[rR]|\+|\-)+`)

	cleaned1 := cleaner1.ReplaceAllString(string(raw), "")
	cleaned2 := cleaner2.ReplaceAllString(cleaned1, "")
	deduped := deduper.ReplaceAllString(cleaned2, "${1}")
	spaced1 := spacer1.ReplaceAllString(deduped, "${modifier}${digits} ")
	spaced2 := spacer2.ReplaceAllString(spaced1, "${xd} ${digits}")
	split := strings.Split(strings.TrimSpace(spaced2), " ")

	return split
}

func parseFromArgs(expressionArgs ExpressionArgs) (Expression, error) {
	var err error
	exp := Expression{
		Iterations: 1,
		Modifier:   0,
		Casts:      0,
		Die:        0,
		DropLowest: false,
		RerollOnes: false,
	}

	for i := range expressionArgs {
		arg := expressionArgs[i]

		if arg == "D" {
			exp.DropLowest = true
		}

		if arg == "r" {
			exp.RerollOnes = true
		}

		if arg == "D" || arg == "d" {
			if i > 0 {
				exp.Casts, err = parseIntFromString(expressionArgs[i-1])
				if err != nil {
					return exp, fmt.Errorf("Can't parse Cast #")
				}
			}
			if i < len(expressionArgs)-1 {
				exp.Die, err = parseIntFromString(expressionArgs[i+1])
				if err != nil {
					return exp, fmt.Errorf("Can't parse Die #")
				}
			}
		}

		if arg == "X" || arg == "x" {
			if i == 0 {
				return exp, fmt.Errorf("Missing the Iteration # before the 'x'")
			}
			exp.Iterations, err = parseIntFromString(expressionArgs[i-1])
			if err != nil {
				return exp, fmt.Errorf("Can't parse Iteration #")
			}
		}

		if string(arg[0]) == "+" || string(arg[0]) == "-" {
			exp.Modifier, err = parseIntFromString(arg)
			if err != nil {
				return exp, fmt.Errorf("Can't parse Modifier #")
			}
		}
	}

	if exp.RerollOnes && exp.Die == 1 {
		exp.RerollOnes = false
	}

	if exp.Iterations > 100 {
		return exp, fmt.Errorf("Max Iterations is 100.")
	}

	if exp.Die <= 0 {
		return exp, fmt.Errorf("Missing or invalid Die #")
	}

	if exp.Die > 10000 {
		return exp, fmt.Errorf("Max Die is 10000")
	}

	exp.Pretty = fmt.Sprintf("%dd%d", exp.Casts, exp.Die)

	if exp.Modifier < 0 {
		exp.Pretty = exp.Pretty + fmt.Sprintf("%d", exp.Modifier)
	}

	if exp.Modifier > 0 {
		exp.Pretty = exp.Pretty + fmt.Sprintf("+%d", exp.Modifier)
	}

	if exp.RerollOnes {
		exp.Pretty = exp.Pretty + "r"
	}

	return exp, nil
}

func New(raw RawExpression) (*Expression, error) {
	args := split(raw)
	expression, err := parseFromArgs(args)
	return &expression, err
}

var waitGroup sync.WaitGroup

func usage() {
	fmt.Println("Usage: roll <expression> [expression ...]")
	fmt.Println("  <expression> ::= [iterations] <cast> [modifier] [rerollOnes]")
	fmt.Println("  <iterations  ::= <digits> x")
	fmt.Println("  <cast>       ::= <dice_count> <d_or_drop> <die_size>")
	fmt.Println("  <dice_count> ::= <digits>")
	fmt.Println("  <d_or_drop>  ::= 'd' | 'D' ('D' means drop the lowest die)")
	fmt.Println("  <die_size>   ::= <digits>")
	fmt.Println("  <modifier>   ::= [+ | -] <digits>")
	fmt.Println("  <rerollOnes> ::= r")
	fmt.Println("")
	fmt.Println("  Examples: 1d20 or 6x4D6 or 2d8+4r")
	defer waitGroup.Done()
	os.Exit(0)

}

func main() {
	rawExpressions := os.Args[1:]
	expressionCount := len(rawExpressions)
	runtime.GOMAXPROCS(expressionCount)

	if len(rawExpressions) == 0 {
		usage()
	}

	expressions := make([]Expression, expressionCount)

	for i := 0; i < expressionCount; i++ {
		expression, err := New(RawExpression(rawExpressions[i]))
		expressions[i] = *expression

		if err != nil {
			fmt.Println("Error with input:", strings.TrimSpace(rawExpressions[i]), "-> ", err)
			usage()
		}
	}

	for _, expression := range expressions {
		waitGroup.Add(1)
		go func(expression Expression) {
			defer waitGroup.Done()
			RollAndPrint(expression)
		}(expression)
	}

	waitGroup.Wait()
}
