# Final project - Recurrent Unit Circuit Design

## b05902086 周逸

---

1. 設計取捨
    * 一開始花了一段時間考慮要把哪些權重主動儲存在 circuit 上面，而因為最後計算的結果是看 AT 值(面積$\times$cycle數$\times$cycle time)，如果把所有權重資料都存在 circuit 上，雖然會使得總 cycle 數量變很低，但是會導致節省下來的 cycle 數量的倍率跑到面積上面，而這樣會導致 circuit 過大，很難壓 cycle time。因此最後是選擇所有資料都重新讀取。
    * 雖然原本以為把 $B_{ih}$ 及 $B_{hh}$ 放在 Circuit 上可以用少量的 area 換取一些 cycle 數上的節省，但是實際上實作後發現為了存 $B_{ih}$ 及 $B_{hh}$ 會導致多用了大約一半面積，反而得不償失，而 cycle 數只少了$\frac{1}{64}$左右。
2. Stage
    * ~~一開始仔細思考之後，會發現基本上只要依照讀六種不同 memory 的位置來切狀態即可完成，並且會在其中的五個狀態中重複循環。~~(後來為了pipeline和編號的方便，因此改成八個狀態)
3. 乘法器
    * 在寫之前就有預想到乘法部分會變成 critical path，而實際用 design compiler 跑下去結果也是如此。因此使用 booth algorithm 把他變成幾個數字的加法，然後把加總的部分使用 pipeline 來處理，這樣就能壓低 cycle time。
4. Pipeline
    * 盡量把大步驟拆成多個小步驟，然後盡量把小步驟均勻的分散到每個 state 中，使得每個 state 的執行時間都差不多，就能達到pipeline的效果，並壓低 cycle time。
5. 讀寫優化
    * ~~盡量讓每個 register 寫入之後都不要在同個 cycle 中去讀他，可以讓 compiler 更容易的優化這種東西。~~(後來直接把所有的=都換成<=)
6. 乘法和加法單元
    * 因為乘法和加法的部份仍然容易成為 critical path，因此把乘法和加法的部分拉到外面變成單獨一塊，這樣計算乘法和加法前就不需要 stage 等等的判斷。
7. Transistor-level 合成
    * Transistor-level 合成的時候，在 nano Route 這個階段的時候，如果 WNS 不夠大，innovus 會直接 crash。後來發現的解決方法是事先先執行 ECO Design，然後到 Mode 裡面把 Thresholds 裡的 Setup Slack 提高，這樣就能讓WNS變成正比較大的值，而不是 0.000 附近。這樣之後就能順利的讓 nano Route 不會 crash 了。
8. Cycle time
    * 這個 verilog 在 Gate-Level 合成的時候，用 2ns 當 cycle time 也能合成的出來(timing可以得到MET)，但是拿去模擬的時候就會出現問題，而看起來主要都是 hold time violation，但是因為找不到解決的方式，最後只能把 cycle time 調整成 3.6 ns 才不會出錯。
9. 合成參數
    * Gate-Level
      * Cycle time: $3.6$ $ns$
    * Transistor-Level
      * Cycle time: $3.6$ $ns$
10. 結果
    * Gate-level results
        * Can you pass gate-level simulation?
            * yes
        * Cycle time that can pass your gate-level simulation:
            * $3.6$ $ns$
        * Total simulation time:
            * $4685447.578$ $ns$
        * Total cell area:
            * $140038.896131$ $\mu{m^2}$
        * Cell area $\times$ Simulation time:
            * $656144906702.7875$ $\mu{m^2}\cdot{ns}$
    * Transistor-level results
        * Can you pass transistor-level simulation?
            * yes
        * Cycle time that can pass your transistor-level simulation:
            * $3.6$ $ns$
        * Total simulation time:
            * $4685447.569$ $ns$
        * Total cell area:
            * $147578.746$ $\mu{m^2}$
        * Cell area $\times$ Simulation time:
            * $691472476681.7686$ $\mu{m^2}\cdot{ns}$
11. 截圖
    * RTL Pass
     ![_](imgs/註解%202020-06-20%20061807.png)
    * Gate-level Area Report
     ![_](imgs/註解%202020-06-20%20062407.png)
    * Gate-level Timing Report
     ![_](imgs/註解%202020-06-20%20062501.png)
    * Gate-level Pass
     ![_](imgs/註解%202020-06-20%20061053.png)
    * Transistor-level Floorplan
     ![_](imgs/註解%202020-06-20%20051904.png)
     ![_](imgs/註解%202020-06-20%20051927.png)
    * Transistor-level Full placement
     ![_](imgs/註解%202020-06-20%20052046.png)
     ![_](imgs/註解%202020-06-20%20053442.png)
     ![_](imgs/註解%202020-06-20%20053607.png)
    * Transistor-level Power Ring
     ![_](imgs/註解%202020-06-20%20053700.png)
    * Transistor-level Power Stripe
     ![_](imgs/註解%202020-06-20%20053719.png)
     ![_](imgs/註解%202020-06-20%20053758.png)
     ![_](imgs/註解%202020-06-20%20053909.png)
    * Transistor-level CTS
     ![_](imgs/註解%202020-06-20%20054159.png)
     ![_](imgs/註解%202020-06-20%20054240.png)
     ![_](imgs/註解%202020-06-20%20054320.png)
    * Transistor-level Special Route
     ![_](imgs/註解%202020-06-20%20054401.png)
     ![_](imgs/註解%202020-06-20%20054437.png)
    * Transistor-level Nano Route
     ![_](imgs/註解%202020-06-20%20054750.png)
     ![_](imgs/註解%202020-06-20%20054850.png)
     ![_](imgs/註解%202020-06-20%20054919.png)
     ![_](imgs/註解%202020-06-20%20054946.png)
    * Transistor-level Summary
     ![_](imgs/註解%202020-06-20%20062532.png)
    * Transistor-level Pass
     ![_](imgs/註解%202020-06-20%20061726.png)
