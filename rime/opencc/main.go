package main

import (
	"bufio"
	"fmt"
	"log"
	"os"

	"github.com/longbridgeapp/opencc"
)

func main() {
	s2tw, err := opencc.New("s2tw")
	if err != nil {
		log.Fatal(err)
	}

	f, err := os.Open("../luna_pinyin.sogou.dict.yaml")
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()

	newFile, err := os.Create("../luna_pinyin.sougo.tw2.dict.yaml")
	if err != nil {
		log.Fatal(err)
	}
	defer newFile.Close()

	i := 0
	scanner := bufio.NewScanner(f)
	writer := bufio.NewWriter(newFile)
	for scanner.Scan() {
		in := scanner.Text()
		out, err := s2tw.Convert(in)
		if err != nil {
			log.Fatal(err)
		}
		i++
		fmt.Println("deal with line", i)

		_, err = writer.WriteString(out + "\n")
		if err != nil {
			log.Fatal(err)
		}

	}

	if err := scanner.Err(); err != nil {
		log.Fatal(err)
	}
}
