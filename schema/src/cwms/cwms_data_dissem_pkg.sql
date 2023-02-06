CREATE OR REPLACE PACKAGE cwms_data_dissem
/**
   * Routines used to manage the flow of data from Operational CWMS databases
   * to the National CWMS databases. Operational CWMS databases are used by
   * district and division offices to perform their real time reservoir operations.
   * The National CWMS databases are used primarily for data dissemination purposes.
   * There are currently two National CWMS databases, namely a CorpsNet DB and a
   * DMZ DB. The CorpsNet DB is used by internal Corps only accessible services
   * and the DMZ DB is used by public facing services.
   * <p>
   * The user controls the replication of time series from the local to national database(s) by seting the states of two destination filters
   * (one CorpsNet and one for DMZ) on or off, in combination with assigining specific time series to one or more of four time series groups.
   * The time series groups are used only when filtering is turned on for one or both of the destinations.
   * <ul>
   * <li>CorpsNet Filter
   * <ul>
   * <li><b>When turned off</b><em> all time series</em> are replicated to CorpsNet</li>
   * <li><b>When turned on</b> the following time series catagory/groups control which time series are replicated
   * <ul>
   * <li>Data Dissemination/CorpsNet Include List</li>
   * <li>Data Dissemination/CorpsNet Exclude List</li>
   * </ul>
   * </li>
   * </ul>
   * </li>
   * <li>DMZ Filter
   * <ul>
   * <li><b>When turned off</b><em> all time series</em> are replicated to the DMZ (requires CorpsNet filter to also be turned off)</li>
   * <li><b>When turned on</b> the following time series catagory/groups control which time series are replicated
   * <ul>
   * <li>Data Dissemination/DMZ Include List</li>
   * <li>Data Dissemination/DMZ Exclude List</li>
   * </ul>
   * </li>
   * </ul>
   * </li>
   * </ul>
   * <p>
   * Any time series will be replicated to the CorpsNet and DMZ databases according to
   * the following conditions.
   * <table class="descr">
   * <tr><th class="descr">Replication to CorpsNet</th></tr>
   * <tr>
   * <td class="descr">
   * Filtering to CorpsNet is turned off (set to FALSE)<br>
   * <b>~OR~</b><br>
   * Both of the following are true:
   * <ul>
   * <li>The time series <b>is</b> assigned to the <b>Data Dissemination/CorpsNet Include List</b> time series category/group</li>
   * <li>The time series <b>is not</b> assigned to the <b>Data Dissemination/CorpsNet Exclude List</b> time series category/group</li>
   * </ul>
   * </td>
   * </tr>
   * <tr><th class="descr">Replication to DMZ</th></tr>
   * <tr>
   * <td class="descr">
   * Filtering to DMZ is turned off (set to FALSE) (requires filtering to CorpsNet to be turned off)<br>
   * <b>~OR~</b><br>
   * All of the following are true:
   * <ul>
   * <li>The time series <b>is</b> assigned to the <b>Data Dissemination/DMZ Include List</b> time series category/group</li>
   * <li>The time series <b>is not</b> assigned to the <b>Data Dissemination/DMZ Exclude List</b> time series category/group</li>
   * <li>The time series <b>is not</b> assigned to the <b>Data Dissemination/CorpsNet Exclude List</b> time series category/group (it need not be included in the the <b>Data Dissemination/CorpsNet Include List</b> time series category/list)</li>
   * </ul>
   * </td>
   * </tr>
   * </table>
   * <p>
   * There are 48 valid state combinations of the 2 filtering settings and inclusion in the 4 time series groups (3 sets of 16 group
   * inclusion states since one of the 4 possible filtering states is not valid). The following table lists each valid state with the
   * corresponding output from <a href=#function%20allowed_to_corpsnet(p_ts_code%20in%20number)>Allowed_To_CorpsNet</a>, <a href=#function%20allowed_to_dmz(p_ts_code%20in%20number)>Allowed_to_Dmz</a>, <a href=#function%20allowed_dest(p_ts_code%20in%20number)>Allowed_Dest</a>, and <a href=#procedure%20cat_ts_transfer(p_ts_transfer_cat%20in%20out%20sys_refcursor,p_office_id%20in%20varchar2)>Cat_Ts_Transfer</a> routines. Of these, state 35 is perhaps unexpected but is consistent with the conditions listed above.
   * <table class="descr">
   * <tr><th class="descr">State</th><th class="descr-bl">Filtering to CorpsNet</th><th class="descr-br">Filtering to DMZ</th><th class="descr">In CorpsNet Include List</th><th class="descr">In CorpsNet Exclude List</th><th class="descr">In DMZ Include List</th><th class="descr-br">In DMZ Exclude List</th><th class="descr">Allowed_To_CorpsNet()</th><th class="descr">Allowed_To_Dmz()</th><th class="descr">Allowed_Dest()</th><th class="descr">Destination DB in Cat_Ts_Transfer()</th></tr>
   * <tr><td class="descr-center">01</td><td class="descr-center-bl">F</td><td class="descr-center-br">F</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center-br">F</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">2</td><td class="descr">DMZ</td></tr>
   * <tr><td class="descr-center">02</td><td class="descr-center-bl">F</td><td class="descr-center-br">F</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">2</td><td class="descr">DMZ</td></tr>
   * <tr><td class="descr-center">03</td><td class="descr-center-bl">F</td><td class="descr-center-br">F</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center">T</td><td class="descr-center-br">F</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">2</td><td class="descr">DMZ</td></tr>
   * <tr><td class="descr-center">04</td><td class="descr-center-bl">F</td><td class="descr-center-br">F</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center">T</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">2</td><td class="descr">DMZ</td></tr>
   * <tr><td class="descr-center">05</td><td class="descr-center-bl">F</td><td class="descr-center-br">F</td><td class="descr-center">F</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center-br">F</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">2</td><td class="descr">DMZ</td></tr>
   * <tr><td class="descr-center">06</td><td class="descr-center-bl">F</td><td class="descr-center-br">F</td><td class="descr-center">F</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">2</td><td class="descr">DMZ</td></tr>
   * <tr><td class="descr-center">07</td><td class="descr-center-bl">F</td><td class="descr-center-br">F</td><td class="descr-center">F</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center-br">F</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">2</td><td class="descr">DMZ</td></tr>
   * <tr><td class="descr-center">08</td><td class="descr-center-bl">F</td><td class="descr-center-br">F</td><td class="descr-center">F</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">2</td><td class="descr">DMZ</td></tr>
   * <tr><td class="descr-center">09</td><td class="descr-center-bl">F</td><td class="descr-center-br">F</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center-br">F</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">2</td><td class="descr">DMZ</td></tr>
   * <tr><td class="descr-center">10</td><td class="descr-center-bl">F</td><td class="descr-center-br">F</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">2</td><td class="descr">DMZ</td></tr>
   * <tr><td class="descr-center">11</td><td class="descr-center-bl">F</td><td class="descr-center-br">F</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">T</td><td class="descr-center-br">F</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">2</td><td class="descr">DMZ</td></tr>
   * <tr><td class="descr-center">12</td><td class="descr-center-bl">F</td><td class="descr-center-br">F</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">T</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">2</td><td class="descr">DMZ</td></tr>
   * <tr><td class="descr-center">13</td><td class="descr-center-bl">F</td><td class="descr-center-br">F</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center-br">F</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">2</td><td class="descr">DMZ</td></tr>
   * <tr><td class="descr-center">14</td><td class="descr-center-bl">F</td><td class="descr-center-br">F</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">2</td><td class="descr">DMZ</td></tr>
   * <tr><td class="descr-center">15</td><td class="descr-center-bl">F</td><td class="descr-center-br">F</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center-br">F</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">2</td><td class="descr">DMZ</td></tr>
   * <tr><td class="descr-center">16</td><td class="descr-center-bl">F</td><td class="descr-center-br">F</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">2</td><td class="descr">DMZ</td></tr>
   * <tr><td class="descr-center">17</td><td class="descr-center-bl">F</td><td class="descr-center-br">T</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center-br">F</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">1</td><td class="descr">CorpsNet</td></tr>
   * <tr><td class="descr-center">18</td><td class="descr-center-bl">F</td><td class="descr-center-br">T</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">1</td><td class="descr">CorpsNet</td></tr>
   * <tr><td class="descr-center">19</td><td class="descr-center-bl">F</td><td class="descr-center-br">T</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center">T</td><td class="descr-center-br">F</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">2</td><td class="descr">DMZ</td></tr>
   * <tr><td class="descr-center">20</td><td class="descr-center-bl">F</td><td class="descr-center-br">T</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center">T</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">1</td><td class="descr">CorpsNet</td></tr>
   * <tr><td class="descr-center">21</td><td class="descr-center-bl">F</td><td class="descr-center-br">T</td><td class="descr-center">F</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center-br">F</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">1</td><td class="descr">CorpsNet</td></tr>
   * <tr><td class="descr-center">22</td><td class="descr-center-bl">F</td><td class="descr-center-br">T</td><td class="descr-center">F</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">1</td><td class="descr">CorpsNet</td></tr>
   * <tr><td class="descr-center">23</td><td class="descr-center-bl">F</td><td class="descr-center-br">T</td><td class="descr-center">F</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center-br">F</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">1</td><td class="descr">CorpsNet</td></tr>
   * <tr><td class="descr-center">24</td><td class="descr-center-bl">F</td><td class="descr-center-br">T</td><td class="descr-center">F</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">1</td><td class="descr">CorpsNet</td></tr>
   * <tr><td class="descr-center">25</td><td class="descr-center-bl">F</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center-br">F</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">1</td><td class="descr">CorpsNet</td></tr>
   * <tr><td class="descr-center">26</td><td class="descr-center-bl">F</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">1</td><td class="descr">CorpsNet</td></tr>
   * <tr><td class="descr-center">27</td><td class="descr-center-bl">F</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">T</td><td class="descr-center-br">F</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">2</td><td class="descr">DMZ</td></tr>
   * <tr><td class="descr-center">28</td><td class="descr-center-bl">F</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">T</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">1</td><td class="descr">CorpsNet</td></tr>
   * <tr><td class="descr-center">29</td><td class="descr-center-bl">F</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center-br">F</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">1</td><td class="descr">CorpsNet</td></tr>
   * <tr><td class="descr-center">30</td><td class="descr-center-bl">F</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">1</td><td class="descr">CorpsNet</td></tr>
   * <tr><td class="descr-center">31</td><td class="descr-center-bl">F</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center-br">F</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">1</td><td class="descr">CorpsNet</td></tr>
   * <tr><td class="descr-center">32</td><td class="descr-center-bl">F</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">1</td><td class="descr">CorpsNet</td></tr>
   * <tr><td class="descr-center">33</td><td class="descr-center-bl">T</td><td class="descr-center-br">T</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center-br">F</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center">0</td><td class="descr"></td></tr>
   * <tr><td class="descr-center">34</td><td class="descr-center-bl">T</td><td class="descr-center-br">T</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center-br">T</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center">0</td><td class="descr"></td></tr>
   * <tr><td class="descr-center">35</td><td class="descr-center-bl">T</td><td class="descr-center-br">T</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center">T</td><td class="descr-center-br">F</td><td class="descr-center">F</td><td class="descr-center">T</td><td class="descr-center">2</td><td class="descr">DMZ</td></tr>
   * <tr><td class="descr-center">36</td><td class="descr-center-bl">T</td><td class="descr-center-br">T</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center">T</td><td class="descr-center-br">T</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center">0</td><td class="descr"></td></tr>
   * <tr><td class="descr-center">37</td><td class="descr-center-bl">T</td><td class="descr-center-br">T</td><td class="descr-center">F</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center-br">F</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center">0</td><td class="descr"></td></tr>
   * <tr><td class="descr-center">38</td><td class="descr-center-bl">T</td><td class="descr-center-br">T</td><td class="descr-center">F</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center-br">T</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center">0</td><td class="descr"></td></tr>
   * <tr><td class="descr-center">39</td><td class="descr-center-bl">T</td><td class="descr-center-br">T</td><td class="descr-center">F</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center-br">F</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center">0</td><td class="descr"></td></tr>
   * <tr><td class="descr-center">40</td><td class="descr-center-bl">T</td><td class="descr-center-br">T</td><td class="descr-center">F</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center-br">T</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center">0</td><td class="descr"></td></tr>
   * <tr><td class="descr-center">41</td><td class="descr-center-bl">T</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center-br">F</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">1</td><td class="descr">CorpsNet</td></tr>
   * <tr><td class="descr-center">42</td><td class="descr-center-bl">T</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">1</td><td class="descr">CorpsNet</td></tr>
   * <tr><td class="descr-center">43</td><td class="descr-center-bl">T</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">T</td><td class="descr-center-br">F</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">2</td><td class="descr">DMZ</td></tr>
   * <tr><td class="descr-center">44</td><td class="descr-center-bl">T</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">T</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center">1</td><td class="descr">CorpsNet</td></tr>
   * <tr><td class="descr-center">45</td><td class="descr-center-bl">T</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center-br">F</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center">0</td><td class="descr"></td></tr>
   * <tr><td class="descr-center">46</td><td class="descr-center-bl">T</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">F</td><td class="descr-center-br">T</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center">0</td><td class="descr"></td></tr>
   * <tr><td class="descr-center">47</td><td class="descr-center-bl">T</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center-br">F</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center">0</td><td class="descr"></td></tr>
   * <tr><td class="descr-center">48</td><td class="descr-center-bl">T</td><td class="descr-center-br">T</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center">T</td><td class="descr-center-br">T</td><td class="descr-center">F</td><td class="descr-center">F</td><td class="descr-center">0</td><td class="descr"></td></tr>
   * </table>
   *
   * @author Various
   *
   * @since CWMS 2.1
   */
AS
   do_not_stream              CONSTANT INT := 0;
   stream_to_CorpsNet         CONSTANT INT := 1;
   stream_to_dmz              CONSTANT INT := 2;

   DMZ_DB                     CONSTANT VARCHAR2 (16) := 'DMZ';
   CorpsNet_DB                CONSTANT VARCHAR2 (16) := 'CORPSNET';

   data_dissem_cat_id         CONSTANT AT_TS_CATEGORY.TS_CATEGORY_ID%TYPE := 'Data Dissemination';
   CorpsNet_include_gp_id     CONSTANT AT_TS_GROUP.TS_GROUP_ID%TYPE := 'CorpsNet Include List';
   CorpsNet_exclude_gp_id     CONSTANT AT_TS_GROUP.TS_GROUP_ID%TYPE := 'CorpsNet Exclude List';
   DMZ_include_gp_id          CONSTANT AT_TS_GROUP.TS_GROUP_ID%TYPE := 'DMZ Include List';
   DMZ_exclude_gp_id          CONSTANT AT_TS_GROUP.TS_GROUP_ID%TYPE := 'DMZ Exclude List';

   CorpsNet_include_gp_code   AT_TS_GROUP.TS_GROUP_CODE%TYPE;
   CorpsNet_exclude_gp_code   AT_TS_GROUP.TS_GROUP_CODE%TYPE;
   DMZ_include_gp_code        AT_TS_GROUP.TS_GROUP_CODE%TYPE;
   DMZ_exclude_gp_code        AT_TS_GROUP.TS_GROUP_CODE%TYPE;

   -- not documented
   TYPE cat_ts_transfer_rec_t IS RECORD
   (
      cwms_ts_id    VARCHAR2(191),
      public_name   VARCHAR2 (57),
      office_id     VARCHAR2 (16),
      ts_code       NUMBER,
      office_code   NUMBER,
      dest_db       VARCHAR2 (16)
   );

   -- not documented
   TYPE cat_ts_transfer_tab_t IS TABLE OF cat_ts_transfer_rec_t;
   FUNCTION get_dest (p_ts_code IN NUMBER)
      RETURN INT;

   /**
    * This function is used to determine if the data for the specified time series
    * should be transferred to the CorpsNet (internal) CWMS National Database, to
    * both the CorpsNet and DMZ CWMS National Databases, not transferred at all.
    *
    * @param p_ts_code The ts_code of the time series of interest.
    *
    * @return The function returns an INT that indicates to which CWMS Databases the p_ts_code should be streamed:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Returned INT</th>
    *     <th class="descr">Indicates</th>
    *   </tr>
    *   <tr>
    *     <td class="descr">0</td>
    *     <td class="descr">Data for this ts_code should not be streamed.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">1</td>
    *     <td class="descr">Data for this ts_code should be streamed to the CorpsNet CWMS National Database.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr">2</td>
    *     <td class="descr">Data for this ts_code should be streamed to both the CorpsNet and the DMZ CWMS National Databases.</td>
    *   </tr>
    * </table>
    *
    */
   FUNCTION allowed_dest (p_ts_code IN NUMBER)
      RETURN INT;

   /**
    * Returns a Boolean indicating if data for the specified ts_code is to be streamed to the DMZ CWMS National Database.
    *
    * @param p_ts_code The ts_code of the time series of interest.
    *
    *
    * @return TRUE if data should be streamed to the DMZ CWMS National DB. FALSE if data should not be streamed to the DMZ CWMS National DB.
    *
    */
   FUNCTION allowed_to_dmz (p_ts_code IN NUMBER)
      RETURN BOOLEAN;

   /**
    * Returns a Boolean indicating if data for the specified ts_code is to be streamed to the CorpsNet CWMS National Database.
    *
    * @param p_ts_code The ts_code of the time series of interest.
    *
    *
    * @return TRUE if data should be streamed to the CorpsNet CWMS National DB. FALSE if data should not be streamed to the CorpsNet CWMS National DB.
    *
    */
   FUNCTION allowed_to_corpsnet (p_ts_code IN NUMBER)
      RETURN BOOLEAN;

   /**
    * Returns a Boolean indicating if filtering to the specified destination
    * database is enabled (TRUE) or disabled (FALSE).
    *
    * @param p_dest_db is the destination database. Valid values include
    *        <code><big>DMZ</big></code> or <code><big>CorpsNet</big></code>
    *
    * @param p_office_id the office identifier for which to find the code. If
    *        <code><big>NULL</big></code> the calling user's office is used
    *
    * @return TRUE if filtering is enabled for the specified destination
    *        database. Returns FALSE if filtering is disabled for the specified
    *        destination database.
    *
    * @throws ERROR if the specified destination database is invalid
    */
   FUNCTION is_filtering_to (p_dest_db IN VARCHAR2, p_office_id IN VARCHAR2)
      RETURN BOOLEAN;



   /**
    * Used to set (enable or disable) time series filtering to the CorpsNet
    * and/or DMZ Databases. If time series Filtering is enabled (TRUE) then
    * only data defined in the offices time series filters for the CorpsNet and
    * DMZ databases will be streamed. If time series filtering is disabled,
    * then all data is streamed to the respective databases. The default setting is:
    * <br>
    * CorpsNet DB: Filtering is disabled (FALSE) resulting in all time series data
    * being streamed to the CorpsNet DB
    * <br>
    * DMZ DB: Filtering is enabled (TRUE) resulting in only data from listed time
    * series ids getting streamed to the DMZ DB. Initially, the DMZ time series
    * include list will be empty, meaning nothing will be streamed to the DMZ DB
    * until an office populates its DMZ include/exclude lists.
    *
    * @param p_filter_to_corpsnet TRUE enables Filtering to the CorpsNet DB, FALSE disables Filtering.
    * @param p_filter_to_dmz TRUE enables Filtering to the DMZ DB, FALSE disables Filtering.
    * @param p_office_id the office identifier for which the filterig is being configured.
    *
    */
   PROCEDURE set_ts_filtering (p_filter_to_corpsnet   IN VARCHAR2,
                               p_filter_to_dmz        IN VARCHAR2,
                               p_office_id            IN VARCHAR2);

   /**
    * Retrieves a cursor of time series ids that will be streamed from the an
    * offices Operational CWMS database to the CorpsNet and possible on to the
    * DMZ CWMS databases.
    *
    * @param p_ts_transfer_cat       A cursor containing the list of time series
    * that will be streamed on to the CorpsNet and/or DMZ CWMS databases. The cursor
    * contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">cwms_ts_id</td>
    *     <td class="descr"varchar2(191)</td>
    *     <td class="descr">The time series identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">public_name</td>
    *     <td class="descr">varchar2(57)</td>
    *     <td class="descr">The Public Name of the time series ids Location.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office id associated with this time series id.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">ts_code</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The corresponding ts_code of the time series id.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">office_code</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The corresponding office_code of the office_id.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">dest_db</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The Destination DB for this time series. The current values are either CorpsNet which means data for this time series is only streamed to the CorpsNet DB or DMZ, which means data for this time series is streamed to both the CorpsNet and the DMZ DBs.</td>
    *   </tr>
    * </table>
    * @param p_officeid        The office that owns the time series
    */
   PROCEDURE cat_ts_transfer (
      p_ts_transfer_cat   IN OUT SYS_REFCURSOR,
      p_office_id         IN     VARCHAR2 DEFAULT NULL);

   /**
    * Retrieves a table of time series data for a specified time series and time window
    *
    * @param p_office_id       The office that owns the time series
    *
    * @return  A collection containing the list of time series
    * that will be streamed on to the CorpsNet and/or DMZ CWMS databases. The collection
    * contains the following columns:
    * <p>
    * <table class="descr">
    *   <tr>
    *     <th class="descr">Column No.</th>
    *     <th class="descr">Column Name</th>
    *     <th class="descr">Data Type</th>
    *     <th class="descr">Contents</th>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">1</td>
    *     <td class="descr">cwms_ts_id</td>
    *     <td class="descr"varchar2(191)</td>
    *     <td class="descr">The time series identifier</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">2</td>
    *     <td class="descr">public_name</td>
    *     <td class="descr">varchar2(57)</td>
    *     <td class="descr">The Public Name of the time series ids Location.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">3</td>
    *     <td class="descr">office_id</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The office id associated with this time series id.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">4</td>
    *     <td class="descr">ts_code</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The corresponding ts_code of the time series id.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">5</td>
    *     <td class="descr">office_code</td>
    *     <td class="descr">number</td>
    *     <td class="descr">The corresponding office_code of the office_id.</td>
    *   </tr>
    *   <tr>
    *     <td class="descr-center">6</td>
    *     <td class="descr">dest_db</td>
    *     <td class="descr">varchar2(16)</td>
    *     <td class="descr">The Destination DB for this time series. The current values are either CorpsNet which means data for this time series is only streamed to the CorpsNet DB or DMZ, which means data for this time series is streamed to both the CorpsNet and the DMZ DBs.</td>
    *   </tr>
    * </table><p>
    * The record collection is suitable for casting to a table with the table() function.
    */
   FUNCTION cat_ts_transfer_tab (p_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN cat_ts_transfer_tab_t
      PIPELINED;
end cwms_data_dissem;
/
show errors
