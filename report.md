# Final project - Recurrent Unit Circuit Design

## b05902086 周逸

---

1. 設計取捨
    * 一開始花了一段時間考慮要把哪些權重主動儲存在 circuit 上面，而因為最後計算的結果是看 AT 值(面積$\times$cycle數$\times$cycle time)，如果把所有權重資料都存在 circuit 上，雖然會使得總 cycle 數量變很低，但是會導致節省下來的 cycle 數量的倍率跑到面積上面，而這樣會導致 circuit 過大，很難壓 cycle time。因此最後是選擇所有資料都重新讀取。
    * 雖然原本以為把 $B_{ih}$ 及 $B_{hh}$ 放在 Circuit 上可以用少量的 area 換取一些 cycle 數上的節省，但是實際上實作後發現為了存 $B_{ih}$ 及 $B_{hh}$ 會導致多用了大約一半面積，反而得不償失，而 cycle 數只少了$\frac{1}{64}$左右。
2. Stage
    * 一開始仔細思考之後，會發現基本上只要依照讀六種不同 memory 的位置來切狀態即可完成，並且會在其中的五個狀態中重複循環。
3. 乘法器
    * 在寫之前就有預想到乘法部分會變成 critical path，而實際用 design compiler 跑下去結果也是如此。因此把一個大乘法拆成多段小的乘法，然後把加總的部分放到下個 cycle 處理，這樣就能壓低 cycle time。
4. activation function
    * 把乘法壓低後，critical path 就變成了計算 activation function 到傳出結果到 mdata_w 的這段，因為這段只有半個 cycle 的時間可以運算(其它的運算都是在下次的 posedge 前能計算出結果就好，但是送出的資料則必須要在 negedge 前計算完成)，因此把 activation function 跟送出的部分拆開成兩個階段，雖然會讓總 cycle 數量多大約1%，卻可以讓 cycle time 繼續往下壓，因此這也是個好的優化。
5. Pipeline
    * 盡量把大步驟拆成多個小步驟，然後盡量把小步驟均勻的分散到每個 state 中，使得每個 state 的執行時間都差不多，就能達到pipeline的效果，並壓低 cycle time。
6. 讀寫優化
    * 盡量讓每個 register 寫入之後都不要在同個 cycle 中去讀他，可以讓 compiler 更容易的優化這種東西。
7. 乘法和加法單元
    * 因為乘法和加法的部份仍然容易成為 critical path，因此把乘法和加法的部分拉到外面變成單獨一塊，這樣計算乘法和加法前就不需要 stage 等等的判斷。
8. Transistor-level 合成 
    * Transistor-level 合成的時候，在 nano Route 這個階段的時候，如果 WNS 不夠大，innovus 會直接 crash，因此後來發現的解決方法是事先先執行 ECO Design，然後到 Mode 裡面把 Thresholds 裡的 Setup Slack 提高，這樣就能讓WNS變成正比較大的值，而不是 0.000 附近。這樣之後就能順利的讓 nano Route 不會 crash 了。
9. 合成 Cycle time
    * Gate-Level: $3.8$ $ns$
    * Transistor-Level: $3.8$ $ns$
10. 結果
    * Gate-level results
        * Can you pass gate-level simulation?
            * yes
        * Cycle time that can pass your gate-level simulation:
            * $3.8$ $ns$ 
        * Total simulation time:
            * $4848466.532$ $ns$
        * Total cell area: 
            * $169135.726395$ $\mu{m^2}$
        * Cell area $\times$ Simulation time: 
            * $820048908791.6665$ $\mu{m^2}\cdot{ns}$
    * Transistor-level results
        * Can you pass transistor-level simulation?
            * yes
        * Cycle time that can pass your transistor-level simulation:
            * $3.8$ $ns$ 
        * Total simulation time:
            * $4848466.528$ $ns$
        * Total cell area: 
            * $188070.223$ $\mu{m^2}$
        * Cell area $\times$ Simulation time: 
            * $911852181128.9957$ $\mu{m^2}\cdot{ns}$
11. 截圖
    * RTL Pass
     ![_](imgs/註解%202020-06-18%20065409.png)
    * Gate-level Area Report
     ![_](imgs/註解%202020-06-18%20072457.png)
    * Gate-level Timing Report
     ![_](imgs/註解%202020-06-18%20072530.png)
    * Gate-level Pass
     ![_](imgs/註解%202020-06-18%20070207.png)
    * Transistor-level Floorplan
     ![_](imgs/註解%202020-06-18%20062548.png)
     ![_](imgs/註解%202020-06-18%20062616.png)
    * Transistor-level Full placement
     ![_](imgs/註解%202020-06-18%20063300.png)
     ![_](imgs/註解%202020-06-18%20063320.png)
     ![_](imgs/註解%202020-06-18%20063424.png)
    * Transistor-level Power Ring
     ![_](imgs/註解%202020-06-18%20063538.png)
    * Transistor-level Power Stripe
     ![_](imgs/註解%202020-06-18%20063627.png)
     ![_](imgs/註解%202020-06-18%20063716.png)
     ![_](imgs/註解%202020-06-18%20063740.png)
    * Transistor-level CTS
     ![_](imgs/註解%202020-06-18%20064246.png)
     ![_](imgs/註解%202020-06-18%20064314.png)
     ![_](imgs/註解%202020-06-18%20064339.png)
    * Transistor-level Special Route
     ![_](imgs/註解%202020-06-18%20064431.png)
     ![_](imgs/註解%202020-06-18%20064456.png)
    * Transistor-level Nano Route
     ![_](imgs/註解%202020-06-18%20064942.png)
     ![_](imgs/註解%202020-06-18%20073415.png)
     ![_](imgs/註解%202020-06-18%20065044.png)
     ![_](imgs/註解%202020-06-18%20065117.png)
    * Transistor-level Summary
     ![_](imgs/註解%202020-06-18%20072604.png)
    * Transistor-level Pass
     ![_](imgs/註解%202020-06-18%20065409.png)
