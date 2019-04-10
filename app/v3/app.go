package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
)

func handler(w http.ResponseWriter, r *http.Request) {
	wait, ok := r.URL.Query()["wait"]

	if ok && len(wait) > 0 {
		d, err := time.ParseDuration(wait[0])
		if err != nil {
			w.WriteHeader(http.StatusBadRequest)
			return
		}
		time.Sleep(d)
	}

	check, ok := r.URL.Query()["check"]
	var extra string
	if ok && len(check) > 0 {
		extra = check[0]
	}

	fmt.Fprintf(
		w,
		"Hi there %s!! - %s\n",
		os.Getenv("NAME"), extra,
	)
}

func main() {
	http.HandleFunc("/", handler)
	log.Fatal(http.ListenAndServe(":8080", nil))
}
