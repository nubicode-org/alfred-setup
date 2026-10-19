package main

import (
	"errors"
	"net"
	"strings"
	"testing"
	"time"
)

func TestListeningPortPasses(t *testing.T) {
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer ln.Close()
	port := ln.Addr().(*net.TCPAddr).Port

	if _, err := check("127.0.0.1", port, 2*time.Second); err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestUnresolvableNameIsWrapped(t *testing.T) {
	_, err := check("no-such-host.invalid", 443, 2*time.Second)
	if err == nil {
		t.Fatal("expected an error")
	}
	var dnsErr *net.DNSError
	if !errors.As(err, &dnsErr) {
		t.Fatalf("the DNS error should survive wrapping, got %T: %v", err, err)
	}
	if !strings.HasPrefix(err.Error(), "resolve no-such-host.invalid:") {
		t.Fatalf("the message should say what failed, got %q", err)
	}
}
