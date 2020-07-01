package main

import (
	"fmt"
	"github.com/chorn/rollers/golang/roll/dice"
	"os"
	"strings"
)

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
	os.Exit(0)
}

func main() {
	if len(os.Args[1:]) == 0 {
		usage()
	}

	for _, raw := range os.Args[1:] {
		rolls, err := dice.Roll(raw)

		if err != nil {
			fmt.Println("Error with input: ", raw, " -> ", err)
		} else {
			fmt.Println(strings.Join(rolls, "\n"))
		}
	}
}
