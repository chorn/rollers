package dice

import (
	"crypto/rand"
	"fmt"
	"math"
	"math/big"
	"sort"
	"strings"
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
