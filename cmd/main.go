package main

import (
	"bufio"
	"context"
	"fmt"
	"io"
	"os"
	"strings"

	"github.com/docker/docker/api/types"
	"github.com/docker/docker/api/types/container"
	"github.com/docker/docker/client"
)

type ImageFlavor string

const (
	Debian  ImageFlavor = "Debian"
	Ubuntu              = "Ubuntu"
	Centos              = "CentOS"
	Alpine              = "Alpine"
	Unknown             = "Unknown"
)

func main() {
	if len(os.Args) != 3 {
		usage()
		os.Exit(1)
	}
	ret, txt := checkPackages(os.Args[1], os.Args[2])
	if !ret {
		fmt.Printf("Unauthorized packages found: %s\n", txt)
		os.Exit(1)
	}
	os.Exit(0)
}

func usage() {
	fmt.Printf(`Usage:
	checkpackages IMAGE POLICY_PATH
`)
}

func checkPackages(image, policy_path string) (bool, string) {
	installed := getPackageList(image)
	blacklist, exceptions := getPolicy(policy_path)
	return compare(blacklist, exceptions, installed)
}

func compare(blacklist_pkgs, exceptions, installed_pkgs []string) (bool, string) {
	ret := true
	var unauthorized_pkgs string

	for _, blacklist := range blacklist_pkgs {
		for _, installed := range installed_pkgs {
			if strings.Contains(installed, blacklist) {
				// check if package is an exception
				if !isException(installed, exceptions) {
					ret = false
					unauthorized_pkgs += " " + installed
				}

			}

		}
	}
	return ret, unauthorized_pkgs
}

func isException(installed string, exceptions []string) bool {
	for _, exception := range exceptions {
		if strings.Contains(installed, exception) {
			return true
		}
	}
	return false
}

func getPolicy(path string) ([]string, []string) {
	file, err := os.Open(path)
	if err != nil {
		fmt.Printf("Error: could not open policy file\n%s", err)
		os.Exit(1)
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	scanner.Split(bufio.ScanLines)
	var blacklist []string
	var exceptions []string
	for scanner.Scan() {
		tmp := scanner.Text()
		if len(tmp) > 0 {
			if strings.HasPrefix(tmp, "!") {
				exceptions = append(exceptions, tmp[1:])
			} else {
				blacklist = append(blacklist, tmp)
			}
		}
	}

	if len(blacklist) == 0 {
		fmt.Println("Error: empty policy")
		os.Exit(1)
	}
	return blacklist, exceptions
}

func getPackageList(image string) []string {
	var cmd []string

	switch getFlavor(image) {
	case Debian, Ubuntu:
		cmd = []string{"dpkg", "-l"}
	case Centos:
		cmd = []string{"rpm", "-qa"}
	case Alpine:
		cmd = []string{"apk", "info"}
	}

	var ret []string
	out := execContainerCmd(image, cmd)
	lines := strings.Split(out, "\n")
	for _, line := range lines {
		words := strings.Fields(line)
		if len(words) > 1 {
			ret = append(ret, words[1])
		}
	}
	return ret
}

func getFlavor(image string) ImageFlavor {
	out := execContainerCmd(image, []string{"cat", "/etc/os-release"})

	if strings.Contains(out, "Debian") {
		return Debian
	} else if strings.Contains(out, "Ubuntu") {
		return Ubuntu
	} else if strings.Contains(out, "CentOS") {
		return Centos
	} else if strings.Contains(out, "Alpine") {
		return Alpine
	} else {
		return Unknown
	}
}

func execContainerCmd(image string, cmd []string) string {
	ctx := context.Background()
	cli, err := client.NewClientWithOpts(client.FromEnv)
	if err != nil {
		fmt.Printf("%s\n", err)
		os.Exit(1)
	}
	cli.NegotiateAPIVersion(ctx)

	containerConfig := &container.Config{
		User:       "root",
		Tty:        false,
		Image:      image,
		Cmd:        cmd,
		Entrypoint: []string{},
	}

	containerName := ""
	resp, err := cli.ContainerCreate(ctx, containerConfig, nil, nil, nil, containerName)
	if err != nil {
		fmt.Printf("%s\n", err)
		os.Exit(1)
	}

	defer cli.ContainerRemove(ctx, resp.ID, types.ContainerRemoveOptions{Force: true})

	err = cli.ContainerStart(ctx, resp.ID, types.ContainerStartOptions{})
	if err != nil {
		fmt.Printf("%s\n", err)
		os.Exit(1)
	}

	statusCh, errCh := cli.ContainerWait(ctx, resp.ID, container.WaitConditionNotRunning)
	select {
	case err := <-errCh:
		if err != nil {
			fmt.Printf("%s\n", err)
			os.Exit(1)
		}
	case <-statusCh:
	}

	out, err := cli.ContainerLogs(ctx, resp.ID, types.ContainerLogsOptions{ShowStdout: true})
	if err != nil {
		fmt.Printf("%s\n", err)
		os.Exit(1)
	}

	buf := new(strings.Builder)
	_, err = io.Copy(buf, out)
	return buf.String()
}
