package main

import (
	"fmt"
	"github.com/chorn/rollers/golang/roll/dice"
	"os"
	"runtime"
	"strings"
	"sync"
)

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

	expressions := make([]dice.Expression, expressionCount)

	for i := 0; i < expressionCount; i++ {
		expression, err := dice.New(dice.RawExpression(rawExpressions[i]))
		expressions[i] = *expression

		if err != nil {
			fmt.Println("Error with input:", strings.TrimSpace(rawExpressions[i]), "-> ", err)
			usage()
		}
	}

	for _, expression := range expressions {
		waitGroup.Add(1)
		go func(expression dice.Expression) {
			defer waitGroup.Done()
			dice.RollAndPrint(expression)
		}(expression)
	}

	waitGroup.Wait()
}
