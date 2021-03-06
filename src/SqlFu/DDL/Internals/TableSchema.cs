using System.Collections.Generic;
using System.Linq;

namespace SqlFu.DDL.Internals
{
    class TableSchema
    {
        public TableSchema(string name)
        {
            Name = name;
            Options= new DbEngineOptions();
            Columns= new ColumnsCollection();
            Constraints = new ConstraintsCollection(this);
            Indexes= new IndexCollection(this);
         
            ModifiedColumns=new ModifiedColumnsCollection(name);
        }
        public string Name { get; set; }
        public IfTableExists CreationOption { get; set; }
        public bool IsTemporary { get; set; }
        internal DbEngineOptions Options { get; private set; }
        public ColumnsCollection Columns { get; private set; }
        public ConstraintsCollection Constraints { get; private set; }
        public IndexCollection Indexes { get; private set; }

      
   
        public ModifiedColumnsCollection ModifiedColumns { get; private set; }
        internal string TableName {get { return Name.Replace(' ', '_'); }}

        internal string ColumnsToName(string columns)
        {
            return string.Join("_", columns.Split(',').Select(s => s.Trim().ToLowerInvariant()));
        }
    }
}