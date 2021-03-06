﻿using EPiServer.Core;
using EPiServer.Core.PropertySettings;
using System;
using System.Linq.Expressions;
using System.Web.Helpers;

namespace Vaultopia.Web.Helpers
{
    public static class PropertyHelpers
    {
        public static string GetPropertySettings<TModel, TProperty, TSettings>(TModel model, Expression<Func<TModel, TProperty>> property)
        where TSettings : IPropertySettings
        {
            var expression = (MemberExpression)property.Body;
            var name = expression.Member.Name;
            
            var settings = ((IContent) model).GetPropertySettings<TSettings>(name);
            var settingsJson = Json.Encode(settings);
            return settingsJson;
        }

    }
}