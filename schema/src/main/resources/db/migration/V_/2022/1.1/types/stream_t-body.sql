create or replace type body stream_t
as 
   /*
   office_id            varchar2(16),
   name                 varchar2(49),
   unit                 varchar2(16),
   stationing_starts_ds varchar2(1),
   flows_into_stream    varchar2(49),
   flows_into_station   binary_double,
   flows_into_bank      varchar2(1),
   diverts_from_stream  varchar2(49),
   diverts_from_station binary_double,
   diverts_from_bank    varchar2(1),
   length               binary_double,
   average_slope        binary_double,
   comments             varchar2(256),
   */
   
   constructor function stream_t
   return self as result
   is
   begin
      return;
   end stream_t;

   constructor function stream_t(
      p_stream_location_code in number)
   return self as result
   is
      l_office_id            varchar2(16);
      l_name                 varchar2(49);
   begin
      begin
         select o.office_id,
                bl.base_location_id
                ||substr('-', 1, length(pl.sub_location_id))
                ||pl.sub_location_id
           into l_office_id,
                l_name 
           from at_stream s,
                at_physical_location pl,
                at_base_location bl,
                cwms_office o
          where s.stream_location_code = p_stream_location_code
            and pl.location_code = s.stream_location_code
            and bl.base_location_code = pl.base_location_code
            and o.office_code = bl.db_office_code;
      exception
         when no_data_found then
            cwms_err.raise(
               'ITEM_DOES_NOT_EXIST',
               'CWMS Stream',
               to_char(p_stream_location_code));
      end;
      self := stream_t(l_name, l_office_id);
      return;
   end stream_t;
   
   constructor function stream_t(
      p_stream_location_id in varchar2,
      p_office_id          in varchar2 default null)
   return self as result
   is
   begin
      self.office_id := nvl(p_office_id, cwms_util.user_office_id);
      self.name      := p_stream_location_id;
      self.unit      := 'm'; 
      cwms_stream.retrieve_stream(
         self.stationing_starts_ds,
         self.flows_into_stream,
         self.flows_into_station,
         self.flows_into_bank,
         self.diverts_from_stream,
         self.diverts_from_station,
         self.diverts_from_bank,
         self.length,
         self.average_slope,
         self.comments,
         self.name,
         self.unit,
         self.office_id
      );
      return;
   end stream_t;
   
   constructor function stream_t(
      p_office_id            in varchar2,
      p_name                 in varchar2,
      p_unit                 in varchar2,
      p_stationing_starts_ds in varchar2,
      p_flows_into_stream    in varchar2,
      p_flows_into_station   in binary_double,
      p_flows_into_bank      in varchar2,
      p_diverts_from_stream  in varchar2,
      p_diverts_from_station in binary_double,
      p_diverts_from_bank    in varchar2,
      p_length               in binary_double,
      p_average_slope        in binary_double,
      p_comments             in varchar2)
   return self as result
   is
   begin
      self.office_id            := p_office_id;
      self.name                 := p_name;
      self.unit                 := p_unit;
      self.stationing_starts_ds := p_stationing_starts_ds;
      self.flows_into_stream    := p_flows_into_stream;
      self.flows_into_station   := p_flows_into_station;
      self.flows_into_bank      := p_flows_into_bank;
      self.diverts_from_stream  := p_diverts_from_stream;
      self.diverts_from_station := p_diverts_from_station;
      self.diverts_from_bank    := p_diverts_from_bank;
      self.length               := p_length;
      self.average_slope        := p_average_slope;
      self.comments             := p_comments;
   end stream_t;
   
   member procedure convert_to_unit(
      p_unit in varchar2)
   is
      l_factor binary_double;
      l_offset binary_double;
   begin
      select factor, offset
        into l_factor, 
             l_offset
        from cwms_unit_conversion
       where from_unit_id = cwms_util.get_unit_id (self.unit)
         and to_unit_id = cwms_util.get_unit_id (p_unit);
      
   
      self.flows_into_station   := self.flows_into_station   * l_factor + l_offset;          
      self.diverts_from_station := self.diverts_from_station * l_factor + l_offset;
      self.length               := self.length               * l_factor + l_offset;
   end convert_to_unit;
   
   member procedure store(
      p_fail_if_exists in varchar2,
      p_ignore_nulls   in varchar2)
   is
   begin
      cwms_stream.store_stream(
         self.name,
         p_fail_if_exists,
         p_ignore_nulls,
         self.unit,
         self.stationing_starts_ds,
         self.flows_into_stream,
         self.flows_into_station,
         self.flows_into_bank,
         self.diverts_from_stream,
         self.diverts_from_station,
         self.diverts_from_bank,
         self.length,
         self.average_slope,
         self.comments,
         self.office_id);
   end store;
end;
/
