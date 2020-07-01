package dice

import (
	"errors"
	"fmt"
	"log"
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

func parseIntFromString(str string) int {
	asInt, err := strconv.ParseInt(str, 0, 32)

	if err != nil {
		log.Fatal(err)
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

func parseFromArgs(expressionArgs []string) Expression {
	exp := Expression{
		Iterations: 1,
		Modifier:   0,
		Casts:      1,
		Die:        20,
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
				exp.Casts = parseIntFromString(expressionArgs[i-1])
			}
			if i < len(expressionArgs)-1 {
				exp.Die = parseIntFromString(expressionArgs[i+1])
			}
		}

		if arg == "X" || arg == "x" {
			if i == 0 {
				log.Fatal(errors.New("You can't start with 'x'"))
			}
			exp.Iterations = parseIntFromString(expressionArgs[i-1])
		}

		if string(arg[0]) == "+" || string(arg[0]) == "-" {
			exp.Modifier = parseIntFromString(arg)
		}
	}

	if exp.RerollOnes && exp.Die == 1 {
		exp.RerollOnes = false
	}

	if exp.Iterations > 100 {
		exp.Iterations = 100
	}

	if exp.Die > 10000 {
		exp.Die = 10000
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

	return exp
}

func Parse(raw string) Expression {
	expressionArgs := splitRawExpression(raw)
	return parseFromArgs(expressionArgs)
}
