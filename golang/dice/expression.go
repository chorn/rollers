package dice

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"
)

type Expression struct {
	Iterations int
	Modifier   int
	Casts      int
	Die        int
	DropLowest bool
	RerollOnes bool
	Pretty     string
}

func parseIntFromString(str string) (int, error) {
	asInt, err := strconv.ParseInt(str, 0, 32)

	return int(asInt), err
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

func parseFromArgs(expressionArgs []string) (Expression, error) {
	var err error
	exp := Expression{
		Iterations: 0,
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

	if exp.Die <= 10 {
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

func Parse(raw string) (Expression, error) {
	expressionArgs := splitRawExpression(raw)
	return parseFromArgs(expressionArgs)
}
