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
    * ~~盡量把大步驟拆成多個小步驟，然後盡量把小步驟均勻的分散到每個 state 中，使得每個 state 的執行時間都差不多，就能達到pipeline的效果，並壓低 cycle time。~~(盡量把所有的 delay 超過兩次 40bit 加法的運算都拆開變成多級的 pipeline，然後盡量讓資料輸入的當個 cycle 不要做額外的運算，只把資料存到 register 中，下個cycle才開始運算，並且在輸出前加入幾個 stall ，讓運算有時間算完)
5. 讀寫優化
    * ~~盡量讓每個 register 寫入之後都不要在同個 cycle 中去讀他，可以讓 compiler 更容易的優化這種東西。~~(後來直接把所有的=都換成<=)
6. 乘法和加法單元
    * ~~因為乘法和加法的部份仍然容易成為 critical path，因此把乘法和加法的部分拉到外面變成單獨一塊，這樣計算乘法和加法前就不需要 stage 等等的判斷。~~(後來的設計中，已經把幾乎所有的東西都從 stage 的判斷中拉出去了，這樣可以減少 stage 所造成的 delay)
7. Transistor-level 合成
    * Transistor-level 合成的時候，在 nano Route 這個階段的時候，如果 WNS 不夠大，innovus 會直接 crash。後來發現的解決方法是事先先執行 ECO Design，然後到 Mode 裡面把 Thresholds 裡的 Setup Slack 提高，這樣就能讓WNS變成正比較大的值，而不是 0.000 附近。這樣之後就能順利的讓 nano Route 不會 crash 了。
8. Cycle time
    * 這個 verilog 在 Gate-Level 合成的時候，用 2ns 當 cycle time 也能合成的出來 (timing 可以得到 MET)，但是拿去模擬的時候就會出現問題，而看起來主要都是 hold time violation，但是因為找不到解決的方式，最後只能把 cycle time 調整成 3.0 ns 才不會出錯。
9. 合成參數
    * Gate-Level
      * Cycle time: $3.0$ $ns$
    * Transistor-Level
      * Cycle time: $3.0$ $ns$
10. 結果
    * Gate-level results
        * Can you pass gate-level simulation?
            * yes
        * Cycle time that can pass your gate-level simulation:
            * $3.0$ $ns$
        * Total simulation time:
            * $3904540.036$ $ns$
        * Total cell area:
            * $146197.063362$ $\mu{m^2}$
        * Cell area $\times$ Simulation time:
            * $570832287042.5577$ $\mu{m^2}\cdot{ns}$
    * Transistor-level results
        * Can you pass transistor-level simulation?
            * yes
        * Cycle time that can pass your transistor-level simulation:
            * $3.0$ $ns$
        * Total simulation time:
            * $3904539.831$ $ns$
        * Total cell area:
            * $154015.286$ $\mu{m^2}$
        * Cell area $\times$ Simulation time:
            * $601358818769.8566$ $\mu{m^2}\cdot{ns}$
11. 截圖
    * RTL Pass
     ![_](imgs/註解%202020-06-21%20003112.png)
    * Gate-level Area Report
     ![_](imgs/註解%202020-06-21%20003222.png)
    * Gate-level Timing Report
     ![_](imgs/註解%202020-06-21%20003244.png)
    * Gate-level Pass
     ![_](imgs/註解%202020-06-21%20004502.png)
    * Transistor-level Floorplan
     ![_](imgs/註解%202020-06-21%20004613.png)
     ![_](imgs/註解%202020-06-21%20004741.png)
    * Transistor-level Full placement
     ![_](imgs/註解%202020-06-21%20004854.png)
     ![_](imgs/註解%202020-06-21%20005012.png)
     ![_](imgs/註解%202020-06-21%20005029.png)
    * Transistor-level Power Ring
     ![_](imgs/註解%202020-06-21%20005130.png)
    * Transistor-level Power Stripe
     ![_](imgs/註解%202020-06-21%20005150.png)
     ![_](imgs/註解%202020-06-21%20005221.png)
     ![_](imgs/註解%202020-06-21%20005251.png)
    * Transistor-level CTS
     ![_](imgs/註解%202020-06-21%20005539.png)
     ![_](imgs/註解%202020-06-21%20005603.png)
     ![_](imgs/註解%202020-06-21%20005641.png)
    * Transistor-level Special Route
     ![_](imgs/註解%202020-06-21%20005709.png)
     ![_](imgs/註解%202020-06-21%20005748.png)
    * Transistor-level Nano Route
     ![_](imgs/註解%202020-06-21%20005848.png)
     ![_](imgs/註解%202020-06-21%20005937.png)
     ![_](imgs/註解%202020-06-21%20010005.png)
     ![_](imgs/註解%202020-06-21%20010038.png)
    * Transistor-level Summary
     ![_](imgs/註解%202020-06-21%20010309.png)
    * Transistor-level Pass
     ![_](imgs/註解%202020-06-21%20010327.png)
