package main

import (
	"fmt"
	"log"
	"math"
	"net/http"
	"os"
	"strconv"
	"time"
)

func handler(w http.ResponseWriter, r *http.Request) {
	var err error
	wait, ok := r.URL.Query()["wait"]

	var d time.Duration
	if ok && len(wait) > 0 {
		d, err = time.ParseDuration(wait[0])
		if err != nil {
			w.WriteHeader(http.StatusBadRequest)
			return
		}
		time.Sleep(d)
	}

	var extra string
	check, ok := r.URL.Query()["check"]
	if ok && len(check) > 0 {
		extra = check[0]
	}

	var value int
	num, ok := r.URL.Query()["num"]
	if ok && len(num) > 0 {
		value, err = strconv.Atoi(num[0])
	}

	var prime bool
	if value > 0 {
		prime = isPrime(value)
	}

	fmt.Fprintf(
		w,
		"Hi there %s!! - %s - %t\n",
		os.Getenv("NAME"), extra, prime,
	)
}

func main() {
	http.HandleFunc("/", handler)
	log.Fatal(http.ListenAndServe(":8080", nil))
}

func isPrime(value int) bool {
	for i := 2; i <= int(math.Floor(float64(value)/2)); i++ {
		if value%i == 0 {
			return false
		}
	}
	return value > 1
}
