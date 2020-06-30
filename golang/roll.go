package main

import (
	"crypto/rand"
	"fmt"
	"math"
	"math/big"
	"os"
	"regexp"
	"sort"
	"strconv"
	"strings"
)

type DiceExpression struct {
	iterations int
	modifier   int
	casts      int
	die        int
	dropLowest bool
	rerollOnes bool
	pretty     string
}

type DiceCast struct {
	rolls    []int
	results  []string
	subTotal int
	total    int
	modifier int
	pretty   string
}

func nope(message string) {
	fmt.Println("Nope: ", message)
	os.Exit(1)
}

func random(max int) int {
	bigMax := big.NewInt(int64(max))
	startsAtZero, _ := rand.Int(rand.Reader, bigMax)
	return int(startsAtZero.Int64()) + 1
}

func parseIntFromString(str string) int {
	asInt, err := strconv.ParseInt(str, 0, 32)

	if err != nil {
		nope(err.Error())
	}

	return int(asInt)
}

func splitRawExpression(raw string) []string {
	cleaner1 := regexp.MustCompile(`\s+`)
	cleaner2 := regexp.MustCompile(`[^xXdDrR\d\+\-]`)
	spacer1 := regexp.MustCompile(`(?P<modifier>[\-\+]*)(?P<digits>\d+)`)
	spacer2 := regexp.MustCompile(`(?P<xd>[xXdD]+)(?P<digits>\d+)`)
	deduper := regexp.MustCompile(`([dD]|[xX]|[rR]|\+|\-)+`)

	cleaned1 := cleaner1.ReplaceAllString(raw, "")
	cleaned2 := cleaner2.ReplaceAllString(cleaned1, "")
	deduped := deduper.ReplaceAllString(cleaned2, "${1}")
	spaced1 := spacer1.ReplaceAllString(deduped, "${modifier}${digits} ")
	spaced2 := spacer2.ReplaceAllString(spaced1, "${xd} ${digits}")
	split := strings.Split(strings.TrimSpace(spaced2), " ")

	return split
}

func newExpression(expressionArgs []string) DiceExpression {
	expression := DiceExpression{
		iterations: 1,
		modifier:   0,
		casts:      1,
		die:        20,
		dropLowest: false,
		rerollOnes: false,
	}

	for i := range expressionArgs {
		arg := expressionArgs[i]

		if arg == "D" {
			expression.dropLowest = true
		}

		if arg == "r" {
			expression.rerollOnes = true
		}

		if arg == "D" || arg == "d" {
			if i > 0 {
				expression.casts = parseIntFromString(expressionArgs[i-1])
			}
			if i < len(expressionArgs)-1 {
				expression.die = parseIntFromString(expressionArgs[i+1])
			}
		}

		if arg == "X" || arg == "x" {
			if i == 0 {
				nope("You can't start with 'x'")
			}
			expression.iterations = parseIntFromString(expressionArgs[i-1])
		}

		if string(arg[0]) == "+" || string(arg[0]) == "-" {
			expression.modifier = parseIntFromString(arg)
		}
	}

	if expression.rerollOnes && expression.die == 1 {
		expression.rerollOnes = false
	}

	if expression.iterations > 100 {
		expression.iterations = 100
	}

	if expression.die > 10000 {
		expression.die = 10000
	}

	expression.pretty = fmt.Sprintf("%dd%d", expression.casts, expression.die)

	if expression.modifier < 0 {
		expression.pretty = expression.pretty + fmt.Sprintf("%d", expression.modifier)
	}

	if expression.modifier > 0 {
		expression.pretty = expression.pretty + fmt.Sprintf("+%d", expression.modifier)
	}

	if expression.rerollOnes {
		expression.pretty = expression.pretty + "r"
	}

	return expression
}

func roll(expression DiceExpression) DiceCast {
	rolls := make([]int, expression.casts)
	results := make([]string, expression.casts)
	rollStrLength := len(fmt.Sprintf("%d", expression.die))
	rollFmt := fmt.Sprintf("%%%ds", rollStrLength+2)
	subTotalFmt := fmt.Sprintf("%%%dd", rollStrLength+1)

	for i := 0; i < expression.casts; i++ {
		var dieRoll int
		for {
			dieRoll = random(expression.die)

			if !expression.rerollOnes || dieRoll != 1 {
				break
			}
		}

		rolls[i] = dieRoll
		results[i] = fmt.Sprintf(" %d ", dieRoll)
	}

	if expression.dropLowest {
		dupe := make([]int, expression.casts)
		copy(dupe, rolls)
		sort.Ints(dupe)
		lowest := dupe[0]
		dropped := false

		for i := 0; i < expression.casts; i++ {

			if !dropped && (rolls[i] == lowest) {
				dropped = true
				results[i] = fmt.Sprintf("[%d]", rolls[i])
				rolls[i] = 0
			}
		}
	}

	cast := DiceCast{
		rolls:    rolls,
		results:  results,
		modifier: expression.modifier,
		total:    0,
	}

	for i := 0; i < expression.casts; i++ {
		results[i] = fmt.Sprintf(rollFmt, results[i])
		cast.subTotal += rolls[i]
	}

	cast.total = cast.subTotal + expression.modifier

	prettyResults := strings.Join(results, " + ")

	subTotalString := fmt.Sprintf(subTotalFmt, cast.subTotal)

	cast.pretty = fmt.Sprintf("%s : %s = %s", expression.pretty, prettyResults, subTotalString)

	if expression.modifier > 0 {
		cast.pretty = fmt.Sprintf("%s + %d = %d", cast.pretty, expression.modifier, cast.total)
	}

	if expression.modifier < 0 {
		cast.pretty = fmt.Sprintf("%s - %d = %d", cast.pretty, int(math.Abs(float64(expression.modifier))), cast.total)
	}

	return cast
}

func rollAll(expression DiceExpression) {
	for i := 1; i <= expression.iterations; i++ {
		cast := roll(expression)
		fmt.Println(cast.pretty)
	}
}

func main() {
	for _, raw := range os.Args[1:] {
		expressionArgs := splitRawExpression(raw)
		expression := newExpression(expressionArgs)
		rollAll(expression)
	}
}
