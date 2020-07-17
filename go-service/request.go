package expression

import (
	// "crypto/rand"
	"fmt"
	// "math"
	// "math/big"
	// "os"
	// "regexp"
	// "runtime"
	// "sort"
	// "strconv"
	// "strings"
	// "sync"
	pb "github.com/chorn/rollers/go-service/roll"
)

// type ExpressionRequest struct {
// 	Iterations int
// 	Modifier   int
// 	Casts      int
// 	Die        int
// 	DropLowest bool
// 	RerollOnes bool
// }

// func (exp *pb.ExpressionRequest) String() string {
// 	str := fmt.Sprintf("%dd%d", exp.Casts, exp.Die)
//
// 	if exp.Modifier < 0 {
// 		str = str + fmt.Sprintf("%d", exp.Modifier)
// 	}
//
// 	if exp.Modifier > 0 {
// 		str = str + fmt.Sprintf("+%d", exp.Modifier)
// 	}
//
// 	if exp.RerollOnes {
// 		str = str + "r"
// 	}
//
// 	return str
// }
