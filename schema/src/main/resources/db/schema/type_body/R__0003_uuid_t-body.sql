create or replace type body uuid_t
as
   /**
    * Constructor - creates a new random UUID
    */
   constructor function uuid_t
      return self as result
   is
   begin
      the_string := random_uuid;
      return;
   end uuid_t;
      
   /**
    * Returns the UUID string
    */
   map member function to_string
      return varchar2
   is
   begin
      return the_string;
   end to_string;
end;
/