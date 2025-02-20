package main

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/0x19/goesl"
	"github.com/kelseyhightower/envconfig"
)

type Cfg struct {
	FreeSwitchHost     string `envconfig:"FREESWITCH_HOST" required:"true"`
	FreeSwitchPort     uint64 `envconfig:"FREESWITCH_PORT" required:"true"`
	FreeSwitchPassword string `envconfig:"FREESWITCH_PASSWORD" required:"true"`
	IgnoredEventNames  string `envconfig:"IGNORED_EVENT_NAMES"`
}

func main() {
	var cfg Cfg

	err := envconfig.Process("", &cfg)

	if err != nil {
		panic(err)
	}

	client, err := goesl.NewClient(
		cfg.FreeSwitchHost,
		uint(cfg.FreeSwitchPort),
		cfg.FreeSwitchPassword,
		10,
	)

	if err != nil {
		panic(err)
	}

	defer client.Close()

	go client.Handle()

	client.Send("events json ALL")

	ignoredEventNames := []string{
		"HEARTBEAT",
		"RE_SCHEDULE",
	}

	ignoredEventNames = append(
		ignoredEventNames,
		strings.Split(cfg.IgnoredEventNames, ",")...,
	)

	isActive := true

	go func() {
	LOOP_EVENT:
		for {
			if !isActive {
				return
			}

			msg, err := client.ReadMessage()

			if err != nil {
				slog.Error(
					"read message error",
					slog.Attr{Key: "message", Value: slog.StringValue(err.Error())},
				)
			}

			eventName := msg.GetHeader("Event-Name")

			for _, e := range ignoredEventNames {
				if e == eventName {
					continue LOOP_EVENT
				}
			}

			fmt.Println("=========")
			fmt.Println(msg.Headers)
		}
	}()

	slog.Info("listening")

	nctx, ncancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer ncancel()

	<-nctx.Done()

	slog.Info("shutting down...")

	isActive = false

	time.Sleep(time.Second * 5)
}
