# Final project - Recurrent Unit Circuit Design 
#### b05902086 周逸
---
1. 設計取捨
    * 一開始花了一段時間考慮要把哪些權重主動儲存在 circuit 上面，而因為最後計算的結果是看AT值(面積$\times$cycle數$\times$cycle time)，如果把所有權重資料都存在 circuit 上，雖然會使得總 cycle 數量變很低，但是會導致節省下來的 cycle 數量的倍率跑到面積上面，而這樣會導致 circuit 過大，很難壓 cycle time。因此最後是選擇所有資料都重新讀取。
    * 雖然原本以為把 $B_{ih}$ 及 $B_{hh}$ 放在Circuit上可以用少量的 area 換取一些 cycle 數上的節省，但是實際上實作後發現為了存 $B_{ih}$ 及 $B_{hh}$ 會導致多用了大約一半面積，反而得不償失，而cycle數只少了$\frac{1}{64}$左右。
2. Stage
    * 一開始仔細思考之後，會發現基本上只要依照讀六種不同memory的位置來切狀態即可完成，並且會在其中的五個狀態中重複循環。
3. 乘法器
    * 在寫之前就有預想到乘法部分會變成 critical path，而實際用 design compiler 跑下去結果也是如此。因此把一個大乘法拆成多段小的乘法，然後把加總的部分放到下個cycle處理，這樣就能壓低cycle time。
4. activation function
    * 把乘法壓低後，critical path 就變成了計算 activation function 到傳出結果到 mdata_w 的這段，因為這段只有半個 cycle 的時間可以運算(其它的運算都是在下次的 posedge 前能計算出結果就好，但是送出的資料則必須要在 negedge 前計算完成)，因此把 activation function 跟送出的部分拆開成兩個階段，雖然會讓總 cycle 數量多大約1%，卻可以讓 cycle time 繼續往下壓，因此這也是個好的優化。
5. 合成 Cycle time
    * Gate-Level: $4.6$ $ns$
    * Transistor-Level: $5.0$ $ns$
5. Timing violation
    * 目前觀察到一件特別的事情就是，合成的時候使用的 cycle time 可以成功合成出來，並且不會有在 design compiler 跟 innovus 中不會出現 violation，但是在 simulation 時就必須把 cycle time 放寬，才能成功模擬。並且還有個特殊的現象是，cycle time 往下調到某個範圍的時候，會在 ncverilog 會在 reset 的階段出現 Timing violation，但是最後還是能正確的模擬出結果。不過當 cycle time 在進一步往下調的時候就會出錯了。
6. 結果
    * Gate-level without Timing violation
        * Can you pass gate-level simulation?
            * yes
        * Cycle time that can pass your gate-level simulation:
            * $7.6$ $ns$
        * Total simulation time:
            * $9745558.055$ $ns$
        * Total cell area: 
            * $193505.297446$ $\mu{m^2}$
        * Cell area $\times$ Simulation time: 
            * $1885817110210.0364$ $\mu{m^2}\cdot{ns}$
    * Transistor-level without Timing violation
        * Can you pass gate-level simulation?
            * yes
        * Cycle time that can pass your gate-level simulation:
            * $6.5$ $ns$
        * Total simulation time:
            * $8335016.681$ $ns$
        * Total cell area: 
            * $203769.475$ $\mu{m^2}$
        * Cell area $\times$ Simulation time: 
            * $1698421973203.6125$ $\mu{m^2}\cdot{ns}$
    * Gate-level results
        * Can you pass gate-level simulation?
            * yes
        * Cycle time that can pass your gate-level simulation:
            * $7.2$ $ns$ 
        * Total simulation time:
            * $9232634.055$ $ns$
        * Total cell area: 
            * $193505.297446$ $\mu{m^2}$
        * Cell area $\times$ Simulation time: 
            * $1786563599022.8442$ $\mu{m^2}\cdot{ns}$
    * Transistor-level results
        * Can you pass gate-level simulation?
            * yes
        * Cycle time that can pass your gate-level simulation:
            * $6.3$ $ns$ 
        * Total simulation time:
            * $8078554.681$ $ns$
        * Total cell area: 
            * $203769.475$ $\mu{m^2}$
        * Cell area $\times$ Simulation time: 
            * $1646162846106.1626$ $\mu{m^2}\cdot{ns}$