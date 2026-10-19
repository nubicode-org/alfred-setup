// Command hostcheck checks that hosts resolve and that a TCP port answers. Exits 1 if any host fails.
package main

import (
	"errors"
	"flag"
	"fmt"
	"net"
	"os"
	"strconv"
	"time"
)

// ErrNoAddress is returned when a name resolves to nothing usable.
var ErrNoAddress = errors.New("no address")

func check(host string, port int, timeout time.Duration) (string, error) {
	addrs, err := net.LookupHost(host)
	if err != nil {
		return "", fmt.Errorf("resolve %s: %w", host, err)
	}
	if len(addrs) == 0 {
		return "", fmt.Errorf("resolve %s: %w", host, ErrNoAddress)
	}
	target := net.JoinHostPort(addrs[0], strconv.Itoa(port))
	conn, err := net.DialTimeout("tcp", target, timeout)
	if err != nil {
		return "", fmt.Errorf("connect %s: %w", target, err)
	}
	conn.Close()
	return target + " answered", nil
}

func main() {
	port := flag.Int("port", 443, "TCP port to try")
	timeout := flag.Duration("timeout", 3*time.Second, "time allowed per host")
	flag.Usage = func() {
		fmt.Fprintln(flag.CommandLine.Output(), "Usage: hostcheck [--port N] [--timeout 3s] host...")
		flag.PrintDefaults()
	}
	flag.Parse()
	if flag.NArg() == 0 {
		flag.Usage()
		os.Exit(2)
	}

	failed := false
	for _, host := range flag.Args() {
		detail, err := check(host, *port, *timeout)
		if err != nil {
			failed = true
			fmt.Printf("FAIL  %-30s %v\n", host, err)
			continue
		}
		fmt.Printf("ok    %-30s %s\n", host, detail)
	}
	if failed {
		os.Exit(1)
	}
}
