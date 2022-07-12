create or replace type body supp_streamflow_meas_t as

    -- constructor function with xmltype
    constructor function supp_streamflow_meas_t(p_xml in xmltype) return self as result is
        function get_text(p_path in varchar2, p_required in boolean default false) return varchar2 is
            l_text varchar2(32767);
        begin
            l_text := cwms_util.get_xml_text(p_xml, p_path);
            if l_text is null and p_required then
                cwms_err.raise('error', 'required element or attribute is null or not found: ' || p_path);
            end if;
            return l_text;
        end get_text;

    begin
        if p_xml is not null then
            if p_xml.getrootelement != 'supplemental-stream-flow-measurement' then
                cwms_err.raise(
                        'ERROR',
                        'Expected <supplemental-stream-flow-measurement>, got <'||p_xml.getrootelement||'>');
            end if;
            self.channel_flow := to_binary_double(get_text('/*/channel-flow', false));
            self.overbank_flow := to_binary_double(get_text('/*/overbank-flow', false));
            self.overbank_max_depth := to_binary_double(get_text('/*/overbank-max-depth', false));
            self.channel_max_depth := to_binary_double(get_text('/*/channel-max-depth', false));
            self.avg_velocity := to_binary_double(get_text('/*/avg-velocity', false));
            self.surface_velocity := to_binary_double(get_text('/*/surface-velocity', false));
            self.max_velocity := to_binary_double(get_text('/*/max-velocity', false));
            self.effective_flow_area := to_binary_double(get_text('/*/effective-flow-area', false));
            self.cross_sectional_area := to_binary_double(get_text('/*/cross-sectional-area', false));
            self.mean_gage := to_binary_double(get_text('/*/mean-gage', false));
            self.top_width := to_binary_double(get_text('/*/top-width', false));
            self.main_channel_area := to_binary_double(get_text('/*/main-channel-area', false));
            self.overbank_area := to_binary_double(get_text('/*/overbank-area', false));
        end if;
        return;
    end supp_streamflow_meas_t;

    -- updated to_xml function to use params_to_xml
    member function to_xml return varchar2 is
        l_text varchar2(32767);
    begin
        l_text := supp_streamflow_params_to_xml(
                self.channel_flow,
                self.overbank_flow,
                self.overbank_max_depth,
                self.channel_max_depth,
                self.avg_velocity,
                self.surface_velocity,
                self.max_velocity,
                self.effective_flow_area,
                self.cross_sectional_area,
                self.mean_gage,
                self.top_width,
                self.main_channel_area,
                self.overbank_area
            );
        return l_text;
    end to_xml;

    -- member function to get error message for logging
    member function get_error_message return varchar2 is
        l_error_message varchar2(32767);
    begin
        l_error_message := 'channel_flow       = ' || to_number(self.channel_flow)
            || chr(10) || chr(9) || 'overbank_flow       = ' || to_number(self.overbank_flow)
            || chr(10) || chr(9) || 'overbank_max_depth  = ' || to_number(self.overbank_max_depth)
            || chr(10) || chr(9) || 'channel_max_depth   = ' || to_number(self.channel_max_depth)
            || chr(10) || chr(9) || 'avg_velocity        = ' || to_number(self.avg_velocity)
            || chr(10) || chr(9) || 'surface_velocity    = ' || to_number(self.surface_velocity)
            || chr(10) || chr(9) || 'max_velocity        = ' || to_number(self.max_velocity)
            || chr(10) || chr(9) || 'effective_flow_area = ' || to_number(self.effective_flow_area)
            || chr(10) || chr(9) || 'cross_sectional_area= ' || to_number(self.cross_sectional_area)
            || chr(10) || chr(9) || 'mean_gage           = ' || to_number(self.mean_gage)
            || chr(10) || chr(9) || 'top_width           = ' || to_number(self.top_width)
            || chr(10) || chr(9) || 'main_channel_area   = ' || to_number(self.main_channel_area)
            || chr(10) || chr(9) || 'overbank_area       = ' || to_number(self.overbank_area);
        return l_error_message;
    end get_error_message;

end;
/
show errors;
