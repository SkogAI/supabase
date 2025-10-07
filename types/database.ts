export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
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
      archon_code_examples: {
        Row: {
          chunk_number: number
          content: string
          content_search_vector: unknown | null
          created_at: string
          embedding_1024: string | null
          embedding_1536: string | null
          embedding_3072: string | null
          embedding_384: string | null
          embedding_768: string | null
          embedding_dimension: number | null
          embedding_model: string | null
          id: number
          llm_chat_model: string | null
          metadata: Json
          source_id: string
          summary: string
          url: string
        }
        Insert: {
          chunk_number: number
          content: string
          content_search_vector?: unknown | null
          created_at?: string
          embedding_1024?: string | null
          embedding_1536?: string | null
          embedding_3072?: string | null
          embedding_384?: string | null
          embedding_768?: string | null
          embedding_dimension?: number | null
          embedding_model?: string | null
          id?: number
          llm_chat_model?: string | null
          metadata?: Json
          source_id: string
          summary: string
          url: string
        }
        Update: {
          chunk_number?: number
          content?: string
          content_search_vector?: unknown | null
          created_at?: string
          embedding_1024?: string | null
          embedding_1536?: string | null
          embedding_3072?: string | null
          embedding_384?: string | null
          embedding_768?: string | null
          embedding_dimension?: number | null
          embedding_model?: string | null
          id?: number
          llm_chat_model?: string | null
          metadata?: Json
          source_id?: string
          summary?: string
          url?: string
        }
        Relationships: [
          {
            foreignKeyName: "archon_code_examples_source_id_fkey"
            columns: ["source_id"]
            isOneToOne: false
            referencedRelation: "archon_sources"
            referencedColumns: ["source_id"]
          },
        ]
      }
      archon_crawled_pages: {
        Row: {
          chunk_number: number
          content: string
          content_search_vector: unknown | null
          created_at: string
          embedding_1024: string | null
          embedding_1536: string | null
          embedding_3072: string | null
          embedding_384: string | null
          embedding_768: string | null
          embedding_dimension: number | null
          embedding_model: string | null
          id: number
          llm_chat_model: string | null
          metadata: Json
          source_id: string
          url: string
        }
        Insert: {
          chunk_number: number
          content: string
          content_search_vector?: unknown | null
          created_at?: string
          embedding_1024?: string | null
          embedding_1536?: string | null
          embedding_3072?: string | null
          embedding_384?: string | null
          embedding_768?: string | null
          embedding_dimension?: number | null
          embedding_model?: string | null
          id?: number
          llm_chat_model?: string | null
          metadata?: Json
          source_id: string
          url: string
        }
        Update: {
          chunk_number?: number
          content?: string
          content_search_vector?: unknown | null
          created_at?: string
          embedding_1024?: string | null
          embedding_1536?: string | null
          embedding_3072?: string | null
          embedding_384?: string | null
          embedding_768?: string | null
          embedding_dimension?: number | null
          embedding_model?: string | null
          id?: number
          llm_chat_model?: string | null
          metadata?: Json
          source_id?: string
          url?: string
        }
        Relationships: [
          {
            foreignKeyName: "archon_crawled_pages_source_id_fkey"
            columns: ["source_id"]
            isOneToOne: false
            referencedRelation: "archon_sources"
            referencedColumns: ["source_id"]
          },
        ]
      }
      archon_document_versions: {
        Row: {
          change_summary: string | null
          change_type: string | null
          content: Json
          created_at: string | null
          created_by: string | null
          document_id: string | null
          field_name: string
          id: string
          project_id: string | null
          task_id: string | null
          version_number: number
        }
        Insert: {
          change_summary?: string | null
          change_type?: string | null
          content: Json
          created_at?: string | null
          created_by?: string | null
          document_id?: string | null
          field_name: string
          id?: string
          project_id?: string | null
          task_id?: string | null
          version_number: number
        }
        Update: {
          change_summary?: string | null
          change_type?: string | null
          content?: Json
          created_at?: string | null
          created_by?: string | null
          document_id?: string | null
          field_name?: string
          id?: string
          project_id?: string | null
          task_id?: string | null
          version_number?: number
        }
        Relationships: [
          {
            foreignKeyName: "archon_document_versions_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "archon_projects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "archon_document_versions_task_id_fkey"
            columns: ["task_id"]
            isOneToOne: false
            referencedRelation: "archon_tasks"
            referencedColumns: ["id"]
          },
        ]
      }
      archon_migrations: {
        Row: {
          applied_at: string | null
          checksum: string | null
          id: string
          migration_name: string
          version: string
        }
        Insert: {
          applied_at?: string | null
          checksum?: string | null
          id?: string
          migration_name: string
          version: string
        }
        Update: {
          applied_at?: string | null
          checksum?: string | null
          id?: string
          migration_name?: string
          version?: string
        }
        Relationships: []
      }
      archon_project_sources: {
        Row: {
          created_by: string | null
          id: string
          linked_at: string | null
          notes: string | null
          project_id: string | null
          source_id: string
        }
        Insert: {
          created_by?: string | null
          id?: string
          linked_at?: string | null
          notes?: string | null
          project_id?: string | null
          source_id: string
        }
        Update: {
          created_by?: string | null
          id?: string
          linked_at?: string | null
          notes?: string | null
          project_id?: string | null
          source_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "archon_project_sources_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "archon_projects"
            referencedColumns: ["id"]
          },
        ]
      }
      archon_projects: {
        Row: {
          created_at: string | null
          data: Json | null
          description: string | null
          docs: Json | null
          features: Json | null
          github_repo: string | null
          id: string
          pinned: boolean | null
          title: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          data?: Json | null
          description?: string | null
          docs?: Json | null
          features?: Json | null
          github_repo?: string | null
          id?: string
          pinned?: boolean | null
          title: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          data?: Json | null
          description?: string | null
          docs?: Json | null
          features?: Json | null
          github_repo?: string | null
          id?: string
          pinned?: boolean | null
          title?: string
          updated_at?: string | null
        }
        Relationships: []
      }
      archon_prompts: {
        Row: {
          created_at: string | null
          description: string | null
          id: string
          prompt: string
          prompt_name: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          description?: string | null
          id?: string
          prompt: string
          prompt_name: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          description?: string | null
          id?: string
          prompt?: string
          prompt_name?: string
          updated_at?: string | null
        }
        Relationships: []
      }
      archon_settings: {
        Row: {
          category: string | null
          created_at: string | null
          description: string | null
          encrypted_value: string | null
          id: string
          is_encrypted: boolean | null
          key: string
          updated_at: string | null
          value: string | null
        }
        Insert: {
          category?: string | null
          created_at?: string | null
          description?: string | null
          encrypted_value?: string | null
          id?: string
          is_encrypted?: boolean | null
          key: string
          updated_at?: string | null
          value?: string | null
        }
        Update: {
          category?: string | null
          created_at?: string | null
          description?: string | null
          encrypted_value?: string | null
          id?: string
          is_encrypted?: boolean | null
          key?: string
          updated_at?: string | null
          value?: string | null
        }
        Relationships: []
      }
      archon_sources: {
        Row: {
          created_at: string
          metadata: Json | null
          source_display_name: string | null
          source_id: string
          source_url: string | null
          summary: string | null
          title: string | null
          total_word_count: number | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          metadata?: Json | null
          source_display_name?: string | null
          source_id: string
          source_url?: string | null
          summary?: string | null
          title?: string | null
          total_word_count?: number | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          metadata?: Json | null
          source_display_name?: string | null
          source_id?: string
          source_url?: string | null
          summary?: string | null
          title?: string | null
          total_word_count?: number | null
          updated_at?: string
        }
        Relationships: []
      }
      archon_tasks: {
        Row: {
          archived: boolean | null
          archived_at: string | null
          archived_by: string | null
          assignee: string | null
          code_examples: Json | null
          created_at: string | null
          description: string | null
          feature: string | null
          id: string
          parent_task_id: string | null
          priority: Database["public"]["Enums"]["task_priority"]
          project_id: string | null
          sources: Json | null
          status: Database["public"]["Enums"]["task_status"] | null
          task_order: number | null
          title: string
          updated_at: string | null
        }
        Insert: {
          archived?: boolean | null
          archived_at?: string | null
          archived_by?: string | null
          assignee?: string | null
          code_examples?: Json | null
          created_at?: string | null
          description?: string | null
          feature?: string | null
          id?: string
          parent_task_id?: string | null
          priority?: Database["public"]["Enums"]["task_priority"]
          project_id?: string | null
          sources?: Json | null
          status?: Database["public"]["Enums"]["task_status"] | null
          task_order?: number | null
          title: string
          updated_at?: string | null
        }
        Update: {
          archived?: boolean | null
          archived_at?: string | null
          archived_by?: string | null
          assignee?: string | null
          code_examples?: Json | null
          created_at?: string | null
          description?: string | null
          feature?: string | null
          id?: string
          parent_task_id?: string | null
          priority?: Database["public"]["Enums"]["task_priority"]
          project_id?: string | null
          sources?: Json | null
          status?: Database["public"]["Enums"]["task_status"] | null
          task_order?: number | null
          title?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "archon_tasks_parent_task_id_fkey"
            columns: ["parent_task_id"]
            isOneToOne: false
            referencedRelation: "archon_tasks"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "archon_tasks_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "archon_projects"
            referencedColumns: ["id"]
          },
        ]
      }
      categories: {
        Row: {
          created_at: string
          description: string | null
          id: string
          name: string
          slug: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          name: string
          slug: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          name?: string
          slug?: string
          updated_at?: string
        }
        Relationships: []
      }
      post_categories: {
        Row: {
          category_id: string
          created_at: string
          post_id: string
        }
        Insert: {
          category_id: string
          created_at?: string
          post_id: string
        }
        Update: {
          category_id?: string
          created_at?: string
          post_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "post_categories_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_categories_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
        ]
      }
      posts: {
        Row: {
          content: string | null
          created_at: string
          id: string
          published: boolean
          title: string
          updated_at: string
          user_id: string
        }
        Insert: {
          content?: string | null
          created_at?: string
          id?: string
          published?: boolean
          title: string
          updated_at?: string
          user_id: string
        }
        Update: {
          content?: string | null
          created_at?: string
          id?: string
          published?: boolean
          title?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "posts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          avatar_url: string | null
          bio: string | null
          created_at: string
          full_name: string | null
          id: string
          updated_at: string
          username: string | null
        }
        Insert: {
          avatar_url?: string | null
          bio?: string | null
          created_at?: string
          full_name?: string | null
          id: string
          updated_at?: string
          username?: string | null
        }
        Update: {
          avatar_url?: string | null
          bio?: string | null
          created_at?: string
          full_name?: string | null
          id?: string
          updated_at?: string
          username?: string | null
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
      binary_quantize: {
        Args: { "": string } | { "": unknown }
        Returns: unknown
      }
      detect_embedding_dimension: {
        Args: { embedding_vector: string }
        Returns: number
      }
      get_embedding_column_name: {
        Args: { dimension: number }
        Returns: string
      }
      gtrgm_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gtrgm_decompress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gtrgm_in: {
        Args: { "": unknown }
        Returns: unknown
      }
      gtrgm_options: {
        Args: { "": unknown }
        Returns: undefined
      }
      gtrgm_out: {
        Args: { "": unknown }
        Returns: unknown
      }
      halfvec_avg: {
        Args: { "": number[] }
        Returns: unknown
      }
      halfvec_out: {
        Args: { "": unknown }
        Returns: unknown
      }
      halfvec_send: {
        Args: { "": unknown }
        Returns: string
      }
      halfvec_typmod_in: {
        Args: { "": unknown[] }
        Returns: number
      }
      hnsw_bit_support: {
        Args: { "": unknown }
        Returns: unknown
      }
      hnsw_halfvec_support: {
        Args: { "": unknown }
        Returns: unknown
      }
      hnsw_sparsevec_support: {
        Args: { "": unknown }
        Returns: unknown
      }
      hnswhandler: {
        Args: { "": unknown }
        Returns: unknown
      }
      hybrid_search_archon_code_examples: {
        Args: {
          filter?: Json
          match_count?: number
          query_embedding: string
          query_text: string
          source_filter?: string
        }
        Returns: {
          chunk_number: number
          content: string
          id: number
          match_type: string
          metadata: Json
          similarity: number
          source_id: string
          summary: string
          url: string
        }[]
      }
      hybrid_search_archon_code_examples_multi: {
        Args: {
          embedding_dimension: number
          filter?: Json
          match_count?: number
          query_embedding: string
          query_text: string
          source_filter?: string
        }
        Returns: {
          chunk_number: number
          content: string
          id: number
          match_type: string
          metadata: Json
          similarity: number
          source_id: string
          summary: string
          url: string
        }[]
      }
      hybrid_search_archon_crawled_pages: {
        Args: {
          filter?: Json
          match_count?: number
          query_embedding: string
          query_text: string
          source_filter?: string
        }
        Returns: {
          chunk_number: number
          content: string
          id: number
          match_type: string
          metadata: Json
          similarity: number
          source_id: string
          url: string
        }[]
      }
      hybrid_search_archon_crawled_pages_multi: {
        Args: {
          embedding_dimension: number
          filter?: Json
          match_count?: number
          query_embedding: string
          query_text: string
          source_filter?: string
        }
        Returns: {
          chunk_number: number
          content: string
          id: number
          match_type: string
          metadata: Json
          similarity: number
          source_id: string
          url: string
        }[]
      }
      ivfflat_bit_support: {
        Args: { "": unknown }
        Returns: unknown
      }
      ivfflat_halfvec_support: {
        Args: { "": unknown }
        Returns: unknown
      }
      ivfflathandler: {
        Args: { "": unknown }
        Returns: unknown
      }
      l2_norm: {
        Args: { "": unknown } | { "": unknown }
        Returns: number
      }
      l2_normalize: {
        Args: { "": string } | { "": unknown } | { "": unknown }
        Returns: string
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
      match_archon_code_examples_multi: {
        Args: {
          embedding_dimension: number
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
      match_archon_crawled_pages_multi: {
        Args: {
          embedding_dimension: number
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
      set_limit: {
        Args: { "": number }
        Returns: number
      }
      show_limit: {
        Args: Record<PropertyKey, never>
        Returns: number
      }
      show_trgm: {
        Args: { "": string }
        Returns: string[]
      }
      sparsevec_out: {
        Args: { "": unknown }
        Returns: unknown
      }
      sparsevec_send: {
        Args: { "": unknown }
        Returns: string
      }
      sparsevec_typmod_in: {
        Args: { "": unknown[] }
        Returns: number
      }
      vector_avg: {
        Args: { "": number[] }
        Returns: string
      }
      vector_dims: {
        Args: { "": string } | { "": unknown }
        Returns: number
      }
      vector_norm: {
        Args: { "": string }
        Returns: number
      }
      vector_out: {
        Args: { "": string }
        Returns: unknown
      }
      vector_send: {
        Args: { "": string }
        Returns: string
      }
      vector_typmod_in: {
        Args: { "": unknown[] }
        Returns: number
      }
    }
    Enums: {
      post_status: "draft" | "review" | "published" | "archived"
      priority_level: "low" | "medium" | "high" | "urgent"
      task_priority: "low" | "medium" | "high" | "critical"
      task_status: "todo" | "doing" | "review" | "done"
      user_role: "user" | "moderator" | "admin"
    }
    CompositeTypes: {
      address_info: {
        street_line1: string | null
        street_line2: string | null
        city: string | null
        state: string | null
        postal_code: string | null
        country: string | null
      }
      contact_details: {
        email: string | null
        phone: string | null
        preferred_method: string | null
      }
      geo_location: {
        latitude: number | null
        longitude: number | null
        accuracy_meters: number | null
      }
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
      post_status: ["draft", "review", "published", "archived"],
      priority_level: ["low", "medium", "high", "urgent"],
      task_priority: ["low", "medium", "high", "critical"],
      task_status: ["todo", "doing", "review", "done"],
      user_role: ["user", "moderator", "admin"],
    },
  },
} as const

