package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(
		w,
		"Hi there, sup %s?! \n \t Responding from: %s!!\n",
		os.Getenv("NAME"),
		os.Getenv("HOSTNAME"),
	)
}

func main() {
	http.HandleFunc("/", handler)
	log.Fatal(http.ListenAndServe(":8080", nil))
}
