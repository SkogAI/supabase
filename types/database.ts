export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "13.0.4"
  }
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          extensions?: Json
          operationName?: string
          query?: string
          variables?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      agent_configs: {
        Row: {
          active: boolean | null
          agent_type: string
          capabilities: string[] | null
          config: Json
          created_at: string | null
          id: number
          updated_at: string | null
        }
        Insert: {
          active?: boolean | null
          agent_type: string
          capabilities?: string[] | null
          config: Json
          created_at?: string | null
          id?: number
          updated_at?: string | null
        }
        Update: {
          active?: boolean | null
          agent_type?: string
          capabilities?: string[] | null
          config?: Json
          created_at?: string | null
          id?: number
          updated_at?: string | null
        }
        Relationships: []
      }
      agent_logs: {
        Row: {
          action: string
          agent_type: string
          context: string | null
          details: Json | null
          id: number
          session_id: string | null
          status: string | null
          timestamp: string | null
        }
        Insert: {
          action: string
          agent_type: string
          context?: string | null
          details?: Json | null
          id?: number
          session_id?: string | null
          status?: string | null
          timestamp?: string | null
        }
        Update: {
          action?: string
          agent_type?: string
          context?: string | null
          details?: Json | null
          id?: number
          session_id?: string | null
          status?: string | null
          timestamp?: string | null
        }
        Relationships: []
      }
      agent_tasks: {
        Row: {
          assigned_to: string | null
          completed_at: string | null
          created_at: string | null
          description: string | null
          due_date: string | null
          id: number
          metadata: Json | null
          priority: string | null
          status: string | null
          task_name: string
          updated_at: string | null
        }
        Insert: {
          assigned_to?: string | null
          completed_at?: string | null
          created_at?: string | null
          description?: string | null
          due_date?: string | null
          id?: number
          metadata?: Json | null
          priority?: string | null
          status?: string | null
          task_name: string
          updated_at?: string | null
        }
        Update: {
          assigned_to?: string | null
          completed_at?: string | null
          created_at?: string | null
          description?: string | null
          due_date?: string | null
          id?: number
          metadata?: Json | null
          priority?: string | null
          status?: string | null
          task_name?: string
          updated_at?: string | null
        }
        Relationships: []
      }
      Agents: {
        Row: {
          _attrs: Json | null
          created_at: string | null
          file_size: number | null
          name: string | null
          num_tables: number | null
          uuid: string | null
          version: string | null
        }
        Insert: {
          _attrs?: Json | null
          created_at?: string | null
          file_size?: number | null
          name?: string | null
          num_tables?: number | null
          uuid?: string | null
          version?: string | null
        }
        Update: {
          _attrs?: Json | null
          created_at?: string | null
          file_size?: number | null
          name?: string | null
          num_tables?: number | null
          uuid?: string | null
          version?: string | null
        }
        Relationships: []
      }
      api_results: {
        Row: {
          created_at: string
          id: string
          response_data: Json | null
          status_code: number | null
          updated_at: string
          url: string
        }
        Insert: {
          created_at?: string
          id?: string
          response_data?: Json | null
          status_code?: number | null
          updated_at?: string
          url: string
        }
        Update: {
          created_at?: string
          id?: string
          response_data?: Json | null
          status_code?: number | null
          updated_at?: string
          url?: string
        }
        Relationships: []
      }
      artifacts: {
        Row: {
          content: string | null
          created_at: string | null
          created_by: string | null
          id: number
          metadata: Json | null
          name: string
          path: string | null
          type: string
          updated_at: string | null
        }
        Insert: {
          content?: string | null
          created_at?: string | null
          created_by?: string | null
          id?: number
          metadata?: Json | null
          name: string
          path?: string | null
          type: string
          updated_at?: string | null
        }
        Update: {
          content?: string | null
          created_at?: string | null
          created_by?: string | null
          id?: number
          metadata?: Json | null
          name?: string
          path?: string | null
          type?: string
          updated_at?: string | null
        }
        Relationships: []
      }
      conversation_context: {
        Row: {
          context: Json
          conversation_id: string
          created_at: string | null
          id: number
          participants: string[] | null
          summary: string | null
          updated_at: string | null
        }
        Insert: {
          context: Json
          conversation_id: string
          created_at?: string | null
          id?: number
          participants?: string[] | null
          summary?: string | null
          updated_at?: string | null
        }
        Update: {
          context?: Json
          conversation_id?: string
          created_at?: string | null
          id?: number
          participants?: string[] | null
          summary?: string | null
          updated_at?: string | null
        }
        Relationships: []
      }
      conversations: {
        Row: {
          created_at: string
          id: string
          title: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          title?: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          title?: string
          updated_at?: string
        }
        Relationships: []
      }
      countries: {
        Row: {
          continent: Database["public"]["Enums"]["continents"] | null
          id: number
          iso2: string
          iso3: string | null
          local_name: string | null
          name: string | null
        }
        Insert: {
          continent?: Database["public"]["Enums"]["continents"] | null
          id?: number
          iso2: string
          iso3?: string | null
          local_name?: string | null
          name?: string | null
        }
        Update: {
          continent?: Database["public"]["Enums"]["continents"] | null
          id?: number
          iso2?: string
          iso3?: string | null
          local_name?: string | null
          name?: string | null
        }
        Relationships: []
      }
      events: {
        Row: {
          created_at: string | null
          event_type: string
          id: number
          payload: Json | null
          processed: boolean | null
          processed_at: string | null
          source: string
          target: string | null
        }
        Insert: {
          created_at?: string | null
          event_type: string
          id?: number
          payload?: Json | null
          processed?: boolean | null
          processed_at?: string | null
          source: string
          target?: string | null
        }
        Update: {
          created_at?: string | null
          event_type?: string
          id?: number
          payload?: Json | null
          processed?: boolean | null
          processed_at?: string | null
          source?: string
          target?: string | null
        }
        Relationships: []
      }
      knowledge_base: {
        Row: {
          category: string
          content: string
          created_at: string | null
          created_by: string | null
          id: number
          metadata: Json | null
          tags: string[] | null
          title: string
          updated_at: string | null
        }
        Insert: {
          category: string
          content: string
          created_at?: string | null
          created_by?: string | null
          id?: number
          metadata?: Json | null
          tags?: string[] | null
          title: string
          updated_at?: string | null
        }
        Update: {
          category?: string
          content?: string
          created_at?: string | null
          created_by?: string | null
          id?: number
          metadata?: Json | null
          tags?: string[] | null
          title?: string
          updated_at?: string | null
        }
        Relationships: []
      }
      messages: {
        Row: {
          agent_id: string | null
          content: string
          conversation_id: string
          id: string
          sender: string
          timestamp: string
        }
        Insert: {
          agent_id?: string | null
          content: string
          conversation_id: string
          id?: string
          sender: string
          timestamp?: string
        }
        Update: {
          agent_id?: string | null
          content?: string
          conversation_id?: string
          id?: string
          sender?: string
          timestamp?: string
        }
        Relationships: [
          {
            foreignKeyName: "messages_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "conversations"
            referencedColumns: ["id"]
          },
        ]
      }
      metrics: {
        Row: {
          id: number
          metric_name: string
          source: string | null
          tags: Json | null
          timestamp: string | null
          unit: string | null
          value: number | null
        }
        Insert: {
          id?: number
          metric_name: string
          source?: string | null
          tags?: Json | null
          timestamp?: string | null
          unit?: string | null
          value?: number | null
        }
        Update: {
          id?: number
          metric_name?: string
          source?: string | null
          tags?: Json | null
          timestamp?: string | null
          unit?: string | null
          value?: number | null
        }
        Relationships: []
      }
      profiles: {
        Row: {
          avatar_url: string | null
          full_name: string | null
          id: string
          updated_at: string | null
          username: string | null
          website: string | null
        }
        Insert: {
          avatar_url?: string | null
          full_name?: string | null
          id: string
          updated_at?: string | null
          username?: string | null
          website?: string | null
        }
        Update: {
          avatar_url?: string | null
          full_name?: string | null
          id?: string
          updated_at?: string | null
          username?: string | null
          website?: string | null
        }
        Relationships: []
      }
      request_logs: {
        Row: {
          additional_details: Json | null
          created_at: string | null
          end_user: string | null
          error: Json | null
          id: number
          messages: Json | null
          model: string | null
          response: Json | null
          response_time: number | null
          total_cost: number | null
        }
        Insert: {
          additional_details?: Json | null
          created_at?: string | null
          end_user?: string | null
          error?: Json | null
          id?: number
          messages?: Json | null
          model?: string | null
          response?: Json | null
          response_time?: number | null
          total_cost?: number | null
        }
        Update: {
          additional_details?: Json | null
          created_at?: string | null
          end_user?: string | null
          error?: Json | null
          id?: number
          messages?: Json | null
          model?: string | null
          response?: Json | null
          response_time?: number | null
          total_cost?: number | null
        }
        Relationships: []
      }
      SkogAI: {
        Row: {
          _attrs: Json | null
          created_at: string | null
          file_size: number | null
          name: string | null
          num_tables: number | null
          uuid: string | null
          version: string | null
        }
        Insert: {
          _attrs?: Json | null
          created_at?: string | null
          file_size?: number | null
          name?: string | null
          num_tables?: number | null
          uuid?: string | null
          version?: string | null
        }
        Update: {
          _attrs?: Json | null
          created_at?: string | null
          file_size?: number | null
          name?: string | null
          num_tables?: number | null
          uuid?: string | null
          version?: string | null
        }
        Relationships: []
      }
      todos: {
        Row: {
          id: number
          inserted_at: string
          is_complete: boolean | null
          task: string | null
          user_id: string
        }
        Insert: {
          id?: number
          inserted_at?: string
          is_complete?: boolean | null
          task?: string | null
          user_id: string
        }
        Update: {
          id?: number
          inserted_at?: string
          is_complete?: boolean | null
          task?: string | null
          user_id?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      archive_task: {
        Args: { archived_by_param?: string; task_id_param: string }
        Returns: boolean
      }
      match_archon_code_examples: {
        Args: {
          filter?: Json
          match_count?: number
          query_embedding: string
          source_filter?: string
        }
        Returns: {
          chunk_number: number
          content: string
          id: number
          metadata: Json
          similarity: number
          source_id: string
          summary: string
          url: string
        }[]
      }
      match_archon_crawled_pages: {
        Args: {
          filter?: Json
          match_count?: number
          query_embedding: string
          source_filter?: string
        }
        Returns: {
          chunk_number: number
          content: string
          id: number
          metadata: Json
          similarity: number
          source_id: string
          url: string
        }[]
      }
    }
    Enums: {
      continents:
        | "Africa"
        | "Antarctica"
        | "Asia"
        | "Europe"
        | "Oceania"
        | "North America"
        | "South America"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {
      continents: [
        "Africa",
        "Antarctica",
        "Asia",
        "Europe",
        "Oceania",
        "North America",
        "South America",
      ],
    },
  },
} as const
